%global realname ganglia
%global realversion 3.7.2
%global rpmversion 3.7.2

# locations for things.
%define _topdir /root/%{realname}-build

Name: gmetad
Version: 3.7.2
Release:          1%{?dist}
BuildRoot:        %{_tmppath}/%{realname}-%{version}-%{release}-root-%(%{__id_u} -n)

Summary: DTA - gmetad
Vendor: eshore-isms-dta
License:          ASL 2.0

URL: http://ganglia.org
Source1: %{realname}-%{realversion}.tar.gz

Group: DTA/gmetad

Requires: apr
Requires: pcre
Requires: rrdtool

%description
ganglia gmetad


%clean
rm -rf $RPM_BUILD_ROOT

%prep
%setup -c -T -D -a 1

%build
cd %{realname}-%{realversion}
./configure --with-gmetad --enable-gexec --enable-status --prefix=/usr/local/ganglia
make

%install
cd %{realname}-%{realversion}
make install prefix=$RPM_BUILD_ROOT/usr/local/ganglia
mkdir -p $RPM_BUILD_ROOT/etc/init.d
cp gmetad/gmetad.init $RPM_BUILD_ROOT/etc/init.d/gmetad
cp gmond/gmond.init $RPM_BUILD_ROOT/etc/init.d/gmond
cp -r /usr/local/ganglia/lib* $RPM_BUILD_ROOT/usr/local/ganglia/

%post
ln -s /usr/local/ganglia/sbin/gmetad /usr/sbin/gmetad
ln -s /usr/local/ganglia/sbin/gmond /usr/sbin/gmond
mkdir -p /etc/ganglia
ln -s /usr/local/ganglia/etc/gmetad.conf /etc/ganglia/gmetad.conf
ln -s /usr/local/ganglia/etc/gmond.conf /etc/ganglia/gmond.conf
chkconfig gmetad on
chkconfig gmond on

echo "[LOG] check config location of script '/etc/init.d/gmetad'  vs  config location of 'gmetad -h'"


%files
%defattr(-, root, root)
/etc/init.d/gmetad
/etc/init.d/gmond
/usr/local/ganglia

