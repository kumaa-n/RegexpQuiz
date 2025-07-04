# syntax=docker/dockerfile:1

FROM ruby:3.1.4

RUN apt-get update -qq && \
    apt-get install -y build-essential sqlite3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile* ./
RUN gem install bundler && bundle install
COPY / .
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
