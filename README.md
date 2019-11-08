# Instagram to Mastodon Bridge

> ***This is currently broken (for new installations) because Instagram seems hostile to its users doing anything with their own data.***
> See https://github.com/mcqn/instagram-to-mastodon/issues/4 for more detail.

A simple script to check for new Instagram posts from the authorized account, and copy them across to your Mastodon account.

## Set up

 1. Install the dependencies with `bundle install` (when deploying it rather than developing, you should probably run `bundle install --deployment` to install the gems locally rather than in the system location)
 1. Register a new Instagram client.  Visit [https://www.instagram.com/developer/clients/manage/](https://www.instagram.com/developer/clients/manage/)
 1. Click on "Register a new client"
 1. Fill in the form, we'll be staying in sandbox mode, so it's not too important what you enter here.  We'll call the client "Mastodon Bridge" so it's easy to remember what we built it for.
 1. Copy the Client ID and Client Secret into the relevant fields of your config.yaml file
 1. Run `bundle exec instagram-to-mastodon.rb config.yaml` twice, following the instructions to copy the `auth_code` and then `access_token` into your configuration.
 1. Follow the steps detailed in our [simple posting to Mastodon with Ruby](http://mcqn.com/posts/simple-posting-to-mastodon-with-ruby/) blog post to get the Mastodon `bearer_token` and copy that into config.yaml too.

## Running

Once set up, posting new Instagram photos to Mastodon is merely a case of running `bundle exec instagram-to-mastodon.rb config.yaml`.  You probably want to set up a cron job to run it at regular intervals to pick up new posts as and when they're made.

