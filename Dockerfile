FROM centos:6

RUN yum -y install automake autoconf libtool wget
RUN wget https://github.com/GNOME/libxml2/archive/v2.7.7.tar.gz
RUN tar xvzf v2.7.7.tar.gz
WORKDIR /libxml2-2.7.7
RUN mkdir m4
RUN ./autogen.sh && make 



FROM centos:6

ENV HPQLOCFG_ROOT_TAG="RESPONSES"
ENV ILO_SERVER=""
ENV ILO_USER=""
ENV ILO_PASSWORD=""

RUN yum -y install epel-release
RUN yum -y install wine.i686 wget p7zip

RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
       chmod +x winetricks && \
       ./winetricks -q dotnet40 && \
       rm -f ./winetricks

# https://support.hpe.com/hpsc/swd/public/detail?sp4ts.oid=1009143853&swItemId=MTX_8abe539b67bf46978e8f84acb8&swEnvOid=4184
RUN wget https://downloads.hpe.com/pub/softlib2/software1/pubsw-windows/p1890391843/v142918/SP99166.msi
RUN echo '7035dfb36aff4c69ed0bad76eaa97f0e13a1032d3018e5247dacd111be6ad95e  SP99166.msi' | sha256sum -c -
RUN 7za x -o/bin/hp SP99166.msi && \
    mv -v /bin/hp/_6225B63DC41846ECA163A240F6BC4202 /bin/hp/HPQLOCFG.exe && \
       mv -v /bin/hp/_79AD03A8997347089C1300A26365B858 /bin/hp/HPQLOCFG.exe.config && \
       mv -v /bin/hp/_0012F6305794481B979C1FDABFD347E5 /bin/hp/ReleaseNote.txt && \
       mv -v /bin/hp/_6AABE7DF38594A7C8BA0157C20BAD2CC /bin/hp/iLO.ico && \
       mv -v /bin/hp/_A007224CF1C1432AAC94CCA62864CFEE /bin/hp/HPSSLConnection.dll && \
       mv -v /bin/hp/_3AA87EBBCE874312AAB6B39E84CD35EB /bin/hp/Parser.dll && \
    rm -v SP99166.msi

COPY --from=0 /libxml2-2.7.7/.libs/xmllint /usr/bin/xmllint
COPY entrypoint.sh /bin/hpqlocfg

ENTRYPOINT [ "/bin/hpqlocfg" ]