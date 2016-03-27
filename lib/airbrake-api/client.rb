require 'parallel'
require 'airbrake-api/core_ext/hash'

module AirbrakeAPI
  class Client

    PER_PAGE = 20
    PARALLEL_WORKERS = 10

    attr_accessor *AirbrakeAPI::Configuration::VALID_OPTIONS_KEYS

    def initialize(options={})
      attrs = AirbrakeAPI.options.merge(options)
      AirbrakeAPI::Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", attrs[key])
      end
    end

    def url_for(endpoint, *args)
      path = case endpoint.to_s
      when 'deploys' then deploys_path(*args)
      when 'projects' then '/projects'
      when 'errors' then errors_path(*args)
      when 'error' then error_path(*args)
      when 'notices' then notices_path(*args)
      when 'notice' then notice_path(*args)
      else raise ArgumentError.new("Unrecognized path: #{path}")
      end

      [account_path, path.split('.').first].join('')
    end

    # deploys

    def deploys(project_id, options = {})
      results = request(:get, deploys_path(project_id), options)
      results["deploys"]
    end

    def deploys_path(project_id)
      "/api/v4/projects/#{project_id}/deploys"
    end

    # projects
    def projects_path
      '/api/v4/projects'
    end

    def projects(options = {})
      results = request(:get, projects_path, options)
      results["projects"]
    end

    # errors

    def unformatted_error_path(error_id)
      "/errors/#{error_id}"
    end

    def error_path(error_id)
      "#{unformatted_error_path(error_id)}.xml"
    end

    def errors_path(options={})
      "#{options[:project_id] ? "/projects/#{options[:project_id]}" : nil}/groups.xml"
    end

    def update(error, options = {})
      results = request(:put, unformatted_error_path(error), options)
      results.group
    end

    def error(error_id, options = {})
      results = request(:get, error_path(error_id), options)
      results.group || results.groups
    end

    def errors(options = {})
      options = options.dup
      project_id = options.delete(:project_id)
      results = request(:get, errors_path(:project_id => project_id), options)
      results.group || results.groups
    end

    # notices

    def notice_path(group_id, project_id)
      "/api/v4/projects/#{project_id}/groups/#{group_id}/notices"
    end

    def notices_path(project_id, group_id)
      "/api/v4/projects/#{project_id}/groups/#{group_id}/notices"
    end

    def notice(group_id, project_id, options = {})
      hash = request(:get, notice_path(group_id, project_id), options)
      hash.notice
    end

    def notices(project_id, group_id, options = {}, &block)
      # a specific page is requested, only return that page
      # if no page is specified, start on page 1
      if options[:page]
        page = options[:page]
        options[:pages] = 1
      else
        page = 1
      end

      notices = []
      page_count = 0
      batches = []

      while !options[:pages] || (page_count + 1) <= options[:pages]
        data = request(:get, notices_path(project_id, group_id), :page => page + page_count)
        batch = data["notices"].flatten if data["notices"] != "null"

        yield batch if block_given?

        break if data["notices"] == "null" || batch.size < PER_PAGE
        page_count += 1
        batches << batch
      end
      notices = batches.flatten
    end

    private

    def account_path
      "#{protocol}://#{@account}.airbrake.io"
    end

    def protocol
      @secure ? "https" : "http"
    end

    # Perform an HTTP request
    def request(method, path, params = {}, options = {})

      raise AirbrakeError.new('API Token cannot be nil') if @auth_token.nil?
      raise AirbrakeError.new('Account cannot be nil') if @account.nil?

      response = connection(options).run_request(method, nil, nil, nil) do |request|
        case method
        when :delete, :get
          request.url(path, params.merge(:key => @auth_token))
        when :post, :put
          request.url(path, :key => @auth_token)
          request.body = params unless params.empty?
        end
      end
      response.body
    end

    def connection(options={})
      default_options = {
        :headers => {
          :accept => 'application/json',
          :user_agent => user_agent,
        },
        :ssl => {:verify => false},
        :url => account_path,
      }
      @connection ||= Faraday.new(default_options.deep_merge(connection_options)) do |builder|
        middleware.each { |mw| builder.use *mw }
        builder.adapter adapter
        builder.response :json, :content_type => /\bjson$/
      end
    end

  end
end
