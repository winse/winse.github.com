%global realname ganglia
%global realversion 3.7.2
%global rpmversion 3.7.2

# locations for things.
%define _topdir /root/%{realname}-build

Name: gmond
Version: 3.7.2
Release:          1%{?dist}
BuildRoot:        %{_tmppath}/%{realname}-%{version}-%{release}-root-%(%{__id_u} -n)

Summary: DTA - gmond
Vendor: eshore-isms-dta
License:          ASL 2.0

URL: http://ganglia.org
Source1: %{realname}-%{realversion}.tar.gz

Group: DTA/ganglia

Requires: apr

%description
ganglia gmond


%clean
rm -rf $RPM_BUILD_ROOT

%prep
%setup -c -T -D -a 1

%build
cd %{realname}-%{realversion}
./configure --enable-gexec --enable-status --prefix=/usr/local/ganglia
make

%install
cd %{realname}-%{realversion}
make install prefix=$RPM_BUILD_ROOT/usr/local/ganglia
mkdir -p $RPM_BUILD_ROOT/etc/init.d
cp gmond/gmond.init $RPM_BUILD_ROOT/etc/init.d/gmond
cp -r /usr/local/ganglia/lib* $RPM_BUILD_ROOT/usr/local/ganglia/

%post
ln -s /usr/local/ganglia/sbin/gmond /usr/sbin/gmond
mkdir /etc/ganglia
ln -s /usr/local/ganglia/etc/gmond.conf /etc/ganglia/gmond.conf
chkconfig gmond on

echo "check config location of script '/etc/init.d/gmond'  vs  config location of 'gmond -h'"


%files
%defattr(-, root, root)
/etc/init.d/gmond
/usr/local/ganglia

