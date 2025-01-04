FROM ruby:3.3

# Works but requires named volume binding because we create files before the compose /docs dir mount
# RUN mkdir /docs
# WORKDIR /docs
# RUN gem install jekyll bundler && jekyll new .