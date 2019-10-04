# Dockerfile to create canary

# Pull base image
FROM centos:6.10

# OpenSSL
RUN ( \
    yum install -y perl-core gcc; \
    cd /usr/local/src && curl -O https://www.openssl.org/source/openssl-1.1.1d.tar.gz; \
    tar -zxf openssl-1.1.1d.tar.gz)
RUN ( \
    cd /usr/local/src/openssl-1.1.1d && \
    ./config && \
    make && \
    make install && \
    echo '/usr/local/lib64' > /etc/ld.so.conf.d/usr_lib.conf)

RUN (ldconfig -v)

# OpenSSH
RUN ( \
    yum install -y autoconf zlib-devel pam-devel git; \
    cd /usr/local/src && git clone https://github.com/openssh/openssh-portable)
RUN ( \
    groupadd sshd && useradd -g sshd -c sshd -d / sshd)
RUN ( \
    cd /usr/local/src/openssh-portable && rm -rf .git && \
    autoreconf && \
    ./configure --with-pam && \
    make && \
    make install)

# Apache
RUN ( \
    yum install -y pcre-devel expat-devel && \
    cd /usr/local/src && curl -O http://apache.osuosl.org/httpd/httpd-2.4.41.tar.gz; \
    curl -O http://mirror.reverse.net/pub/apache/apr/apr-1.7.0.tar.gz; \
    curl -O http://mirror.reverse.net/pub/apache/apr/apr-util-1.6.1.tar.gz; \
    tar -zxf httpd-2.4.41.tar.gz; \
    tar -zxf apr-1.7.0.tar.gz; \
    tar -zxf apr-util-1.6.1.tar.gz)
RUN ( \
    cd /usr/local/src/httpd-2.4.41 && \
    mv ../apr-1.7.0 srclib/apr && \
    mv ../apr-util-1.6.1 srclib/apr-util && \
    ./configure --with-included-apr && \
    make && \
    make install)

# Squid v4 requires GCC 4.7+
# GCC 4.8
RUN ( \
    rpm --import http://linuxsoft.cern.ch/cern/slc6X/x86_64/RPM-GPG-KEY-cern; \
    cd /etc/yum.repos.d && curl -O http://linuxsoft.cern.ch/cern/devtoolset/slc6-devtoolset.repo && \
    yum install -y centos-release-scl devtoolset-2-gcc-c++ devtoolset-2-binutils-devel)

# Squid
RUN ( \
    yum install -y automake wget libxml2-devel libcap-devel; \
    cd /usr/local/src && curl -O http://www.squid-cache.org/Versions/v4/squid-4.8.tar.gz; \
    tar -zxf squid-4.8.tar.gz)

RUN ( \
    source scl_source enable devtoolset-2 && \
    cd /usr/local/src/squid-4.8 && \
    ./configure \
        --prefix=/usr \
        --includedir=/usr/include \
        --datadir=/usr/share \
        --bindir=/usr/sbin \
        --libexecdir=/usr/lib/squid \
        --localstatedir=/var \
        --sysconfdir=/etc/squid \
        && \
    make && \
    make install)

#ENTRYPOINT ["/bin/bash"]
CMD cat /etc/centos-release && \
    /usr/local/bin/openssl version && \
    /usr/local/bin/ssh -V && \
    /usr/local/apache2/bin/httpd -v && \
    /usr/sbin/squid -v
