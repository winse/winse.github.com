%global realpathname ganglia
%global realname ganglia-web
%global realversion 3.7.1
%global rpmversion 3.7.1

# locations for things.
%define _topdir /root/%{realpathname}-build

Name: gweb
Version: 3.7.1
Release:          1%{?dist}
BuildRoot:        %{_tmppath}/%{realname}-%{version}-%{release}-root-%(%{__id_u} -n)

Summary: DTA - gweb
Vendor: eshore-isms-dta
License:          ASL 2.0

URL: http://ganglia.org
Source1: %{realname}-%{realversion}.tar.gz

Group: DTA/gweb

%description
ganglia gweb


%clean
rm -rf $RPM_BUILD_ROOT

%prep
%setup -c -T -D -a 1

%build

%install
cd %{realname}-%{realversion}
make install DESTDIR=$RPM_BUILD_ROOT

%files
%defattr(-, root, root)
/var/www/html/ganglia

