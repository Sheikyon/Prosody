-- a custom prosody 0.11 config focused on high security and ease of use across (mobile) clients
-- provided to you by the homebrewserver.club
-- the original config file (prosody.cfg.lua.original) will have more information 
-- https://homebrewserver.club/configuring-a-modern-xmpp-server.html

plugin_paths = { "/usr/src/prosody-modules" } -- non-standard plugin path so we can keep them up to date with mercurial

modules_enabled = {
                "roster"; -- Allow users to have a roster. Recommended ;)
                "saslauth"; -- Authentication for clients and servers. Recommended if you want to log in.
                "tls"; -- Add support for secure TLS on c2s/s2s connections
                "dialback"; -- s2s dialback support
                "disco"; -- Service discovery
                "private"; -- Private XML storage (for room bookmarks, etc.)
                "vcard4"; -- User Profiles (stored in PEP)
                "vcard_legacy"; -- Conversion between legacy vCard and PEP Avatar, vcard
                "version"; -- Replies to server version requests
                "uptime"; -- Report how long server has been running
                "time"; -- Let others know the time here on this server
                "ping"; -- Replies to XMPP pings with pongs
                "register"; --Allows clients to register an account on your server
                "pep"; -- Enables users to publish their mood, activity, playing music and more
                "carbons"; -- XEP-0280: Message Carbons, synchronize messages accross devices
                "smacks"; -- XEP-0198: Stream Management, keep chatting even when the network drops for a few seconds
                "mam"; -- XEP-0313: Message Archive Management, allows to retrieve chat history from server
                "csi_simple"; -- XEP-0352: Client State Indication
                "admin_adhoc"; -- Allows administration via an XMPP client that supports ad-hoc commands
                "blocklist"; -- XEP-0191  blocking of users
                "bookmarks"; -- Synchronize currently joined groupchat between different clients.
                "server_contact_info"; --add contact info in the case of issues with the server
                "presence";
                --"cloud_notify"; -- Support for XEP-0357 Push Notifications for compatibility with ChatSecure/iOS.
                -- iOS typically end the connection when an app runs in the background and requires use of Apple's Push servers to wake up and receive a message. Enabling this module allows your server to do that for your contacts on iOS.
                -- However we leave it commented out as it is another example of vertically integrated cloud platforms at odds with federation, with all the meta-data-based surveillance consequences that that might have.
};

allow_registration = false; -- Enable to allow people to register accounts on your server from their clients, for more information see http://prosody.im/doc/creating_accounts

certificates = "/etc/prosody/certs" -- Path where prosody looks for the certificates see: https://prosody.im/doc/letsencrypt

https_certificate = "prueba.pr.crt"

c2s_require_encryption = true -- Force clients to use encrypted connections

-- Force certificate authentication for server-to-server connections?
-- This provides ideal security, but requires servers you communicate
-- with to support encryption AND present valid, trusted certificates.
-- NOTE: Your version of LuaSec must support certificate verification!
-- For more information see http://prosody.im/doc/s2s#security

s2s_secure_auth = true

pidfile = "/var/run/prosody/prosody.pid"

authentication = "internal_hashed"

-- Archiving
-- If mod_mam is enabled, Prosody will store a copy of every message. This
-- is used to synchronize conversations between multiple clients, even if
-- they are offline. This setting controls how long Prosody will keep
-- messages in the archive before removing them.

archive_expires_after = "1w" -- Remove archived messages after 1 week

log = { --disable for extra privacy
        info = "/var/log/prosody/prosody.log"; -- Change 'info' to 'debug' for verbose logging
        error = "/var/log/prosody/prosody.err";
        "*syslog";
}

    disco_items = { -- allows clients to find the capabilities of your server 
        {"upload.prueba.pr", "file uploads"};
        {"groups.prueba.pr", "group chats"};
    }

-- add contact information for other server admins to contact you about issues regarding your server
-- this is particularly important if you enable public registrations
-- contact_info = { 

admin = { "mailto:mail@mail.xyz" };
--};

VirtualHost "prueba.pr"

-- Enable http_upload to allow image sharing across multiple devices and clients
Component "upload.prueba.pr" "http_upload_external"
http_upload_external_base_url = "https://upload.prueba.pr/"
http_upload_external_secret = "it-is-secret"


---Allow setting up groupchats on this subdomain:
Component "groups.prueba.pr" "muc"
modules_enabled = { "muc_mam", "vcard_muc" } -- enable archives and avatars for group chats

