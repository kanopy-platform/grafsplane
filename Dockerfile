FROM public.ecr.aws/kanopy/crossplane-packager@sha256:d7316c793a0e542937af52af4c1f98df5cb794dccb66c84f36cf306866d9b43b as packager
ARG TAG
COPY /config/*.yaml .
RUN package.bash

FROM scratch
COPY --from=packager package.yaml .
