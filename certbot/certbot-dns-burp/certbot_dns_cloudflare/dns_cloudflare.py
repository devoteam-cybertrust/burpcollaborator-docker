"""DNS Authenticator for Cloudflare."""
""" Ugly hack to support burp collaborator certificates using dnsmasq 
IT DOES NOT WORK WITH CLOUDFLARE!!!!
"""
import logging

#import CloudFlare
import zope.interface

from certbot import errors
from certbot import interfaces
from certbot.plugins import dns_common

import subprocess


logger = logging.getLogger(__name__)


@zope.interface.implementer(interfaces.IAuthenticator)
@zope.interface.provider(interfaces.IPluginFactory)
class Authenticator(dns_common.DNSAuthenticator):
    """DNS Authenticator for Cloudflare

    This Authenticator uses the Cloudflare API to fulfill a dns-01 challenge.
    """

    description = ('Obtain certificates using a DNS TXT record (if you are using Cloudflare for '
                   'DNS).')
    ttl = 120
    chall01 = None
    chall01_vn = None
    chall02 = None
    chall02_vn = None


    def __init__(self, *args, **kwargs):
        super(Authenticator, self).__init__(*args, **kwargs)
        self.chall01 = None
        self.chall01_vn = None
        self.chall02 = None
        self.chall02_vn = None

    def more_info(self):  # pylint: disable=missing-docstring,no-self-use
        return 'This plugin configures a DNS TXT record to respond to a dns-01 challenge using ' + \
               'the Cloudflare API.'

    def _setup_credentials(self):
         return True

    def _perform(self, domain, validation_name, validation):
        self.add_txt_record(domain, validation_name, validation)

    def _cleanup(self, domain, validation_name, validation):
        self.del_txt_record(domain, validation_name, validation)


    def add_txt_record(self,domain, validation_name, validation):
        if self.chall01:
          self.chall02=validation
          self.chall02_vn=validation_name
          print("Launching DNSMASQ...")
          self.launch_dnsmasq(domain)
        else:
          self.chall01=validation
          self.chall01_vn=validation_name
        
    def del_txt_record(self,domain, validation_name, validation):
          return True

    def launch_dnsmasq(self,domain):
         dnsmasq='/usr/sbin/dnsmasq -q --dns-rr='+domain+',257,000569737375656C657473656E63727970742E6F7267 --txt-record='+self.chall01_vn+',"'+self.chall01+'" --txt-record='+self.chall02_vn+',"'+self.chall02+'" --no-resolv --port=53' 
         print("DNSMASQ CMD: \n{}".format(dnsmasq))
         subprocess.Popen(dnsmasq, shell=True, stdout=subprocess.PIPE)

         
