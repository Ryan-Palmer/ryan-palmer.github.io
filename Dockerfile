FROM ruby:3.3

# Works but requires named volume binding because we create files before the compose /src dir mount
# RUN mkdir /src
# WORKDIR /src
# RUN gem install jekyll bundler && jekyll new .