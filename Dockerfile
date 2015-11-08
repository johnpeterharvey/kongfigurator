FROM centos:7
MAINTAINER john.harvey@travelex.com

RUN yum upgrade -y && yum install -y gcc git make ruby ruby-devel

RUN git clone https://github.com/johnpeterharvey/kongfigurator.git
WORKDIR /kongfigurator
RUN gem install bundler && bundle install
ENTRYPOINT ruby main.rb && while true; do sleep 1000; done
