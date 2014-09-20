%define version 0.2.16
%define release 1
%define name smeserver-IM


Summary: Meta-Package to add Instant Messaging capabilities to your SME Server
Name: %{name}
Version: %{version}
Release: %{release}%{?dist}
Epoch: 9
License: GPL
Group: Networking/Daemons
Source: %{name}-%{version}.tar.gz

BuildRoot: /var/tmp/%{name}-%{version}-%{release}-buildroot
BuildArchitectures: noarch
BuildRequires: e-smith-devtools

Obsoletes: smeserver-ejabberd
Provides: smeserver-ejabberd

#Requires: ipasserelle-base
Requires: ejabberd >= 2.1.11
Requires: ejabberd-modules
Requires: smeserver-webapps-common
Requires: smeserver-jappix >= 0.1-3
Requires: smeserver-pam_cas

%description
Meta package to configure Instant Messaging features
on your SME Server

%changelog
* Sat Sep 20 2014 Stephane de Labrusse <stephdl@de-labrusse.fr> 0.2.16-1.sme
- Initial release to SME Server

* Fri Jan 31 2014 Daniel Berteaud <daniel@firewall-services.com> 0.2.16-1
- Raise trafic limit

* Wed Nov 13 2013 Daniel Berteaud <daniel@firewall-services.com> 0.2.15-1
- x86_64 compatibility

* Wed Nov 13 2013 Daniel Berteaud <daniel@firewall-services.com> 0.2.14-1
- Make spectrum optional

* Tue Nov 12 2013 Daniel Berteaud <daniel@firewall-services.com> 0.2.13-1
- New branch for SME9

* Thu Oct 17 2013 Daniel Berteaud <daniel@firewall-services.com> 0.2.12-1
- Update the logo used by Jappix in the portal

* Thu Jul 18 2013 Daniel Berteaud <daniel@firewall-services.com> 0.2.11-1
- Use the CA from pam_cas config, or fallback to the default

* Sat May 4 2013 Daniel Berteaud <daniel@firewall-services.com> 0.2.10-1
- Use TLS for outgoing s2s if available
- Increase rate limits

* Thu Apr 4 2013 Daniel Berteaud <daniel@firewall-services.com> 0.2.9-1
- apply group filters on mod_vcard_ldap
- fix invalid filter in mod_shared_roster_ldap

* Thu Apr 4 2013 Daniel Berteaud <daniel@firewall-services.com> 0.2.8-1
- Specify the XMPP server name in MCD conf

* Thu Feb 21 2013 Daniel Berteaud <daniel@firewall-services.com> 0.2.7-1
- Add a conf fragment to configure XMPP accounts on Thunderbird via MCD
  (requires ipasserelle-gp)

* Fri Nov 30 2012 Daniel Berteaud <daniel@firewall-services.com> 0.2.6-1
- Fix local users ACL

* Fri Sep 28 2012 Daniel Berteaud <daniel@firewall-services.com> 0.2.5-1
- Update the database if it already exist (create missing tables)
- Add SRV records for xmpp-server and xmpp-client

* Thu May 24 2012 Daniel Berteaud <daniel@firewall-services.com> 0.2.4-1
- mod_muc_odbc doesn't seem to work, revert to mnesia

* Wed May 23 2012 Daniel Berteaud <daniel@firewall-services.com> 0.2.3-1
- Enable more odbc modules and requires Ejabberd 2.1.11

* Tue Apr 24 2012 Daniel Berteaud <daniel@firewall-services.com> 0.2.2-1
- Create log dir /var/log/ejabberd.run

* Fri Mar 30 2012 Daniel Berteaud <daniel@firewall-services.com> 0.2.1-1
- use cn as NickNames in LDAP Shared Roster

* Wed Mar 14 2012 Daniel Berteaud <daniel@firewall-services.com> 0.2.0-1
- Migrate to git

* Tue Dec 20 2011 Daniel Berteaud <daniel@firewall-services.com> 0.1-5
- Turn on CAS auth for Jappix
- Cleanup

* Thu Oct 20 2011 Daniel Berteaud <daniel@firewall-services.com> 0.1-4
- Enable http-bind

* Mon Jul 11 2011 Daniel Berteaud <daniel@firewall-services.com> 0.1-3
- Enable pubsub
- Add jappix web frontend support
- Add additional vcard fields mapping
- Configure shared roster based on LDAP

* Wed Jun 22 2011 Daniel Berteaud <daniel@firewall-services.com> 0.1-2
- Fix some typo in fr locale of the panel

* Thu Jan 20 2011 Daniel Berteaud <daniel@firewall-services.com> 0.1-1
- initial release


%prep
%setup -q -n %{name}-%{version}

%build
perl createlinks
%{__mkdir_p} root/var/service/ejabberd/ssl
%{__mkdir_p} root/var/log/ejabberd.run

%install
/bin/rm -rf $RPM_BUILD_ROOT
(cd root   ; /usr/bin/find . -depth -print | /bin/cpio -dump $RPM_BUILD_ROOT)
/bin/rm -f %{name}-%{version}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT \
    --dir '/var/service/ejabberd' 'attr(1755,root,root)' \
    --file '/var/service/ejabberd/down' 'attr(0644,root,root)' \
    --file '/var/service/ejabberd/run' 'attr(0755,root,root)' \
    --dir '/var/service/ejabberd/supervise' 'attr(0700,root,root)' \
    --file '/var/service/ejabberd/control/1' 'attr(0755,root,root)' \
    --file '/var/service/ejabberd/control/2' 'attr(0755,root,root)' \
    --dir '/var/service/ejabberd/log' 'attr(1755,root,root)' \
    --file '/var/service/ejabberd/log/run' 'attr(0755,root,root)' \
    --dir '/var/service/ejabberd/log/supervise' 'attr(0700,root,root)' \
    --dir '/var/log/ejabberd' 'attr(0750,ejabberd,ejabberd)' \
    --dir '/var/log/ejabberd.run' 'attr(0750,smelog,root)' \
    --dir '/var/service/ejabberd/ssl' 'attr(0750,root,ejabberd)' \
  > %{name}-%{version}-filelist
echo "%doc CHANGELOG" >> %{name}-%{version}-filelist

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)

%clean
rm -rf $RPM_BUILD_ROOT

%post

%preun

