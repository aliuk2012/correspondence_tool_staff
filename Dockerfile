FROM ministryofjustice/ruby:2.3.0-webapp-onbuild

ENV PUMA_PORT 3000

EXPOSE $PUMA_PORT

RUN touch /etc/inittab

COPY bin/codename.sh .

# add official postgresql repo
RUN curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(./codename.sh)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    cat /etc/apt/sources.list.d/pgdg.list && \
    rm codename.sh

RUN apt-get update && \
    apt-get install -y ca-certificates \
                       less \
                       postgresql-client-9.5 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && rm -fr *Release* *Sources* *Packages* && \
    truncate -s 0 /var/log/*log

RUN bundle exec rake assets:precompile assets:non_digested \
    SECRET_KEY_BASE=required_but_does_not_matter_for_assets

ENTRYPOINT ["./run.sh"]
