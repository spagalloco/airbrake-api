Airbrake API
===========

A ruby wrapper for the [Airbrake API](http://airbrakeapp.com/pages/api)

Usage
-----

The first thing you need to set is the account name.  This is the same as the web address for your account.

    Airbrake.account = 'myaccount'

Then, you should set the authentication token.

    Airbrake.auth_token = 'abcdefg'

If your account uses ssl then turn it on:

    Airbrake.secure = true

Optionally, you can configure through a single method:

    Airbrake.configure(:account => 'anapp', :auth_token => 'abcdefg', :secure => true)

Once you've configured authentication, you can make calls against the API.  If no token or authentication is given, a AirbrakeError exception will be raised.

Finding Errors
--------------

Errors are paginated, the API responds with 25 at a time, pass an optional params hash for additional pages:

    Airbrake::Error.find(:all)
    Airbrake::Error.find(:all, :page => 2)

To find an individual error, you can find by ID:

    Airbrake::Error.find(error_id)

Find *all* notices of an error:

    Airbrake::Notice.find_all_by_error_id(error_id)

Find an individual notice:

    Airbrake::Notice.find(notice_id, error_id)

To resolve an error via the API:

    Airbrake::Error.update(1696170, :group => { :resolved => true})

Recreate an error:

    STDOUT.sync = true
    Airbrake::Notice.find_all_by_error_id(error_id) do |batch|
      batch.each do |notice|
        result = system "curl --silent '#{notice.request.url}' > /dev/null"
        print (result ? '.' : 'F')
      end
    end

Projects
--------

To retrieve a list of projects:

    Airbrake::Project.find(:all)

Responses
---------

If an error is returned from the API.  A AirbrakeError will be raised.  Successful responses will return a Hashie::Mash object based on the data from the response.


Contributors
------------

* [Matias Käkelä](https://github.com/massive) - SSL Support
* [Jordan Brough](https://github.com/jordan-brough) - Notices
* [Michael Grosser](https://github.com/grosser) - Numerous performance improvements and bug fixes
