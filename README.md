# Correspondence Tools - Staff
[![Build Status](https://travis-ci.org/ministryofjustice/correspondence_tool_staff.svg?branch=develop)](https://travis-ci.org/ministryofjustice/correspondence_tool_staff)
[![Code Climate](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/gpa.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)
[![Test Coverage](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/coverage.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/coverage)
[![Issue Count](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/issue_count.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)
[![Build Status](https://semaphoreci.com/api/v1/aliuk2012/correspondence_tool_staff/branches/master/badge.svg)](https://semaphoreci.com/aliuk2012/correspondence_tool_staff)


A simple application to allow internal staff users to answer correspondence.

## Development

### Working on the Code

Work should be based off of, and PRed to, the master branch. We use the GitHub
PR approval process so once your PR is ready you'll need to have one person
approve it, and the CI tests passing, before it can be merged. Feel free to use
the issue tags on your PR to indicate if it is a WIP or if it is ready for
reviewing.


### Basic Setup

#### Cloning This Repository

Clone this repository change to the new directory

```bash
$ git clone git@github.com:ministryofjustice/correspondence_tool_staff.git
$ cd correspondence_tool_staff
```

#### Building with Docker Compose

This project is buildable with `docker-compose`. Install [Docker for
Mac](https://docs.docker.com/docker-for-mac/) and then run this in the
repository directory:

```
$ docker-compose up
```

This will build and run all the Docker containers locally and publish port 3000
from the web container locally. The application will be available on
http://localhost:3000/


#### Installing Dependencies

**NB**: The instructions below are only required if you want to run the application
natively without Docker. Only use if necessary, otherwise use the "Building with
Docker Compose" instructions above.

<details>
<summary>Latest Version of Ruby</summary>

Install the latest version of ruby as defined in `.ruby-version`.

With rbenv (make sure you are in the repo path):

```
$ rbenv install
$ gem install bundler
```
</details>

<details>
<summary>Installing Postgres 9.5.x</summary>

We use version 9.5.x of PostgreSQL to match what we have in the deployed
environments, and also because the `structure.sql` file generated by PostgreSQL
can change with every different version.

```
$ brew install postgresql@9.5
```
</details>

<details>
<summary>Installing Latest XCode Stand-Alone Command-Line Tools</summary>

May be necessary to ensure that libraries are available for gems, for example
Nokogiri can have problems with `libiconv` and `libxml`.

```
$ xcode-select --install
```
</details>

<details>
<summary>Browser testing</summary>

We use [headless chrome](https://developers.google.com/web/updates/2017/04/headless-chrome)
for Capybara tests, which require JavaScript. You will need to install Chrome >= 59. 
Where we don't require JavaScript to test a feature we use Capybara's default driver 
[RackTest](https://github.com/teamcapybara/capybara#racktest) which is ruby based 
and much faster as it does not require a server to be started.

**Debugging:**

To debug a spec that requires JavaScript, you need to set a environment variable called CHROME_DEBUG.
It can be set to any value you like.

Examples:

```
$ CHROME_DEBUG=1 bundle exec rspec
```

When you have set `CHROME_DEBUG`, you should notice chrome start up and appear on your
taskbar/Docker. You can now click on chrome and watch it run through your tests.
If you have a `binding.pry`  in your tests the browser will stop at that point.
</details>

#### DB Setup

Run these rake tasks to prepare the database for local development.

```
$ rails db:create
$ rails db:migrate
$ rails db:seed
$ rails db:seed:dev:teams
$ rails db:seed:dev:users
```

The above commands will set up a minimal set of teams, roles and users.

In order to populate the database with correspondence items, use the cts script as follows:

```
$ ./cts clear                          # clears all cases from the database
$ ./cts create all                     # creates 2 cases in each state
$ ./cts create -n4 unassigned drafting # create 4 cases each in unassigned and drafting states
$ ./cts --help create                  # display full help text for create command
```

To create 200 cases in various states with various responders for search testing, you can use the following rake task:
```
rake seed:search:data
```


### Additional Setup

#### Libreoffice

Libreoffice is used to convert documents to PDF's so that they can be viewed in a browser.
In production environments, the installation of libreoffice is taken care of during the build
of the docker container (see the Dockerfile).

In localhost dev testing environments, libreoffice needs to be installed using homebrew, and then
the following shell script needs to created with the name ```/usr/local/bin/soffice```:


```
cd /Applications/LibreOffice.app/Contents/MacOS && ./soffice $1 $2 $3 $4 $5 $6
```

The above script is needed by the libreconv gem to do the conversion.

#### BrowserSync Setup

[BrowserSync](https://www.browsersync.io/) is setup and configured for local development
using the [BrowserSync Rails gem](https://github.com/brunoskonrad/browser-sync-rails).
BrowserSync helps us test across different browsers and devices and sync the
various actions that take place.

##### Dependencies

Node.js:
Install using `brew install node` and then check its installed using `node -v` and `npm -v`

- [Team Treehouse](http://blog.teamtreehouse.com/install-node-js-npm-mac)
- [Dy Classroom](https://www.dyclassroom.com/howto-mac/how-to-install-nodejs-and-npm-on-mac-using-homebrew)

##### Installing and running:

Bundle install as normal then
After bundle install:

```bash
bundle exec rails generate browser_sync_rails:install
```

This will use Node.js npm (Node Package Manager(i.e similar to Bundle or Pythons PIP))
to install BrowserSync and this command is only required once. If you run into
problems with your setup visit the [Gems README](https://github.com/brunoskonrad/browser-sync-rails#problems).

To run BrowserSync start your rails server as normal then in a separate terminal window
run the following rake task:

```bash
bundle exec rails browser_sync:start
```

You should see the following output:
```
browser-sync start --proxy localhost:3000 --files 'app/assets, app/views'
[Browsersync] Proxying: http://localhost:3000
[Browsersync] Access URLs:
 ------------------------------------
       Local: http://localhost:3001
    External: http://xxx.xxx.xxx.x:3001
 ------------------------------------
          UI: http://localhost:3002
 UI External: http://xxx.xxx.xxx.x:3002
 ------------------------------------
[Browsersync] Watching files...
```
Open any number of browsers and use either the local or external address and your
browser windows should be sync. If you make any changes to assets or views then all
the browsers should automatically update and sync.

The UI URL are there if you would like to tweak the BrowserSync server and configure it further

#### Emails

Emails are sent using
the [GOVUK Notify service](https://www.notifications.service.gov.uk).
Configuration relies on an API key which is not stored with the project, as even
the test API key can be used to access account information. To do local testing
you need to have an account that is attached to the "Track a query" service, and
a "Team and whitelist" API key generated from the GOVUK Notify service website.
See the instructions in the `.env.example` file for how to setup the correct
environment variable to override the `govuk_notify_api_key` setting.

The urls generated in the mail use the `cts_email_host` and `cts_mail_port`
configuration variables from the `settings.yml`. These can be overridden by
setting the appropriate environment variables, e.g.

```
$ export SETTINGS__CTS_EMAIL_HOST=localhost
$ export SETTINGS__CTS_EMAIL_PORT=5000
```

#### Uploads

Responses and other case attachments are uploaded directly to S3 before being
submitted to the application to be added to the case. Each deployed environment
has the permissions is needs to access the uploads bucket for that environment.
In local development, uploads are place in the
[correspondence-staff-case-uploads-testing](https://s3-eu-west-1.amazonaws.com/correspondence-staff-case-uploads-testing/)
bucket.

You'll need to provide access credentials to the aws-sdk gems to access
it, there are two ways of doing this:

#### Using credentials attached to your IAM account

If you have an MoJ account in AWS IAM, you can configure the aws-sdk with your
access and secret key by placing them in the `[default]` section in
`.aws/credentials`:

1. [Retrieve you keys from your IAM account](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html)<sup>[1](#user-content-footnote-aws-access-key)</sup> if you don't have them already.
2. [Place them in `~/.aws/credentals`](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html)

When using Docker Compose your `~/.aws` will be mounted onto the containers so
that they can use your local credentials transparently.

#### Using shared credentials

Alternatively, if you don't have an AWS account with access to that bucket, you
can get access by using an access and secret key specifically generated for
testing:

1. Retrieve the 'Case Testing Uploads S3 Bucket' key from the Correspondence
   group in Rattic.
2. [Use environment variables to configure the AWS SDK](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html#aws-ruby-sdk-credentials-environment)
   locally.

#### Footnotes

<a name="footnote-aws-access-key">1</a>: When following these instructions, I had to replace step 3 (Continue to Security Credentials) with clicking on *Users* on the left, selecting my account from the list there, and then clicking on "Security Credentials".

#### Dumping the database

We have functionality to create an anonymised copy of the production or staging database. This feature is to be used as a very last resort. If the copy of the database is needed for debugging please consider the following options first:
- seeing if the issue is covered in the feature tests
- trying to track the issue through Kibana
- recreating the issue locally

If the options above do not solve the issue you by create an anonymised dump of the database by running

```
rake db:dump:prod[host]
```

there are also options to create an anonymised version of the local database

```
rake db:dump:local[filename,anon]
```

or a standard copy

```
rake db:dump:local[filename,clear]
```

For more help with the data dump tasks run:

```
rake db:dump:help
```


### Papertrail

The papertrail gem is used as an auditing tool, keeping the old copies of records every time they are
changed.  There are a couple of complexities in using this tool which are described below:

## JSONB fields on the database
The default serializer does not de-serialize the properties column correctly because internally it is
held as JSON, and papertrail serializes the object in YAML.  The custom serializer ```CtsPapertrailSerializer```
takes care of this and reconstitutes the JSON fields correctly.  See ```/spec/lib/papertrail_spec.rb``` for
examples of how to reify a previous version, or get a hash of field values for the previous version.

### Testing

#### Testing in Parallel

This project includes the `parallel_tests` gem which enables multiple CPUs to be used during testing
in order to speed up execution.  

##### To set up parallel testing

1. Create the required number of extra test databases:

```
bundle exec rake parallel:create
```

2. Load the schema into all of the extra test databases:

```
bundle exec rake parallel:load_structure
```

###### To run all the tests in parallel

```
bundle exec rake parallel:spec
```

###### To run only feature tests in parallel

```
bundle exec rake parallel:spec:features
```

###### To run only the non-feature tests in parallel

```
bundle exec rake parallel:spec:non_features
```


### Continuous Integration

Continuous integration is done with Travis. These are performed in parallel
using the same `parallel_tests` gem as is used locally, and is configured using
environment variables set through the Travis settings for our project. Also,
failed tests that generate a screenshot using the `capybara-screenshot` gem will
upload the screenshot to an S3 bucket so that we can have some visibility of
errors. These can be viewed through the [management console]
(https://s3.console.aws.amazon.com/s3/buckets/correspondence-staff-travis-test-failure-screenshots/?region=us-east-1&tab=overview)
(until we sort out permissions for access to the bucket).

Here are the environment variables that control these features:

- *PARALLEL_TESTS* -- The number of parallel tests to run.
- *S3_TEST_SCREENSHOT_ACCESS_KEY_ID* -- The access key id to use to upload screenshots of failed tests
- *S3_TEST_SCREENSHOT_SECRET_ACCESS_KEY* -- The secret access key for the access key id.

### Smoke Tests

The smoke test runs through the process of signing into the service using a dedicated user account setup as Disclosure BMT team member.
It checks that sign in was successful and then randomly views one case in the case list view.  

To run the smoke test, set the following environment variables:

```
SETTINGS__SMOKE_TESTS__USERNAME    # the email address to use for smoke tests
SETTINGS__SMOKE_TESTS__PASSWORD    # The password for the smoketest email account
```

and then run

```
bundle exec rails smoke
```

### Deploying

#### Dockerisation

Docker images are built from a single `Dockerfile` which uses build arguments to
control aspects of the build. The available build arguments are:

- _*development_mode*_ enable by setting to a non-nil value/empty string to
  install gems form the `test` and `development` groups in the `Gemfile`. Used
  when building with `docker-compose` to build development versions of the
  images for local development.
- _*additional_packages*_ set to the list of additional packages to install with
  `apt-get`. Used by the build system to add packages to the `uploads` container:

  ```
      clamav clamav-daemon clamav-freshclam libreoffice
  ```

  These are required to scan the uploaded files for viruses (clamav & Co.) and
  to generate a PDF preview (libreoffice).


# Case Journey
1. **unassigned**  
   A new case entered by a DACU user is created in this state.  It is in this state very
   briefly before it the user assigns it to a team on the next screen.

1. **awaiting_responder**  
   The new case has been assigned to a business unit for response.

1. **drafting**  
   A kilo in the responding business unit has accepted the case.

1. **pending_dacu_clearance**
   For cases that have an approver assignment with DACU Disclosure, as soon as a
   response file is uploaded, the case will transition to pending_dacu disclosure.
   The DACU disclosure team can either clear the case, in which case it goes forward to
   awaiting dispatch, or request changes, in which case it goes back to drafting.

1. **awaiting_dispatch**  
   The Kilo has uploaded at least one response document.

1. **responded**  
   The kilo has marked the response as sent.

1. **closed**  
   The kilo has marked the case as closed.
