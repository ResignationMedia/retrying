%global srcname retrying
%global pkgname retrying
%global sum General-purpose retrying library in Python. 

# Hack %{?dist} on CentOS build hosts
%if 0%{?rhel} == 6
  %define dist .el6
%endif
%if 0%{?rhel} == 7
  %define dist .el7
%endif

Summary: %{sum}
Name: python%{python3_pkgversion}-%{srcname}
Version: %{package_version}
Release: 1%{?dist}
Source0: %{srcname}-%{version}.tar.gz
Group: System Environment/Base
License: Apache-2.0
URL: https://github.com/rholder/retrying 
Vendor: rholder
BuildArch: noarch
BuildRequires: python%{python3_pkgversion}-devel python%{python3_pkgversion}-setuptools python%{python3_pkgversion}-six
Requires: python%{python3_pkgversion}-six
%{?python_provide:%python_provide python%{python3_pkgversion}-%{srcname}}
# Hopefully, we can use this in the future
%{?python_disable_dependency_generator}

%description
%{sum}

%prep
%autosetup -n %{srcname}-%{version}

%build
%py3_build_egg

%install
%py3_install

%clean
rm -rf %{buildroot}

%files
%{python3_sitelib}/%{pkgname}*egg-info/
%{python3_sitelib}/__pycache__/*
%{python3_sitelib}/%{pkgname}.py

%changelog
* Wed Sep 4 2019 Chris Brundage <chris.brundage@atmosphere.tv> 1.3.3-1
- First rpm build

