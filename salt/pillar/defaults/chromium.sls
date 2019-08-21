 {{ salt.loadtracker.load_pillar(sls) }}


# See the following URL (download the zip file for html docs)
# https://www.chromium.org/administrators/policy-templates

# See also:
# https://www.chromium.org/administrators/policy-list-3

chromium:
    autoconfig:
        managed:
            EnableMediaRouter: False
            ShowCastIconInToolbar: False
            DriveDisabled: True
            DriveDisabledOverCellular: True
            SigninAllowed: False
            DeviceAutoUpdateDisabled: True
            DeviceAutoUpdateP2PEnabled: False
        recommended:
            ShowAppsShortcutInBookmarkBar: false
            HomepageLocation: http://docs.demo.com/
            ShowHomeButton: True
            HomepageIsNewTabPage: False
            ManagedBookmarks: 
                - toplevel_name: SoeStack bookmarks
                - name: docs
                  url:  http://docs.demo.com
                - name: services
                  children: 
                    - name: IPA
                      url:  https://infra.demo.com
                    - name: Gitlab
                      url:  http://gitlab.demo.com
                    #- name: Bitbucket
                    #  url:  http://bitbucket.demo.com
                    #- name: Confluence
                    #  url:  http://confluence.demo.com
                    #- name: JIRA
                    #  url:  http://jira.demo.com
                    - name: Grafana Monitoring
                      url:  http://grafana.demo.com
                    - name: Kibana
                      url:  http://kibana.demo.com
                    - name: Elasticsearch
                      url:  http://elasticsearch.demo.com:9200/
                    - name: Nexus (repos)
                      url:  http://nexus.demo.com:7081
                    - name: Ldap Admin
                      url:  http://infra.demo.com/ldapadmin/index.php
                    - name: Printer config
                      url:  http://infra.demo.com:631/
                    - name: Prometheus
                      url:  http://prometheus.demo.com:9090
                    - name: Node Exporter
                      url:  http://0.0.0.0:9100/metrics
                    - name: SKS PGP Key Server
                      url:  http://infra.demo.com:11371/

        documentation: |
            Policy Name: Description
            #Accessibility settings
                ShowAccessibilityOptionsInSystemTrayMenu: Show accessibility options in system tray menu
                LargeCursorEnabled: Enable large cursor
                SpokenFeedbackEnabled: Enable spoken feedback
                HighContrastEnabled: Enable high contrast mode
                VirtualKeyboardEnabled: Enable on-screen keyboard
                StickyKeysEnabled: Enable sticky keys
                DockedMagnifierEnabled: Enable docked magnifier
                KeyboardDefaultToFunctionKeys: Media keys default to function keys
                ScreenMagnifierType: Set screen magnifier type
                DeviceLoginScreenDefaultLargeCursorEnabled: Set default state of the large cursor on the login screen
                DeviceLoginScreenDefaultSpokenFeedbackEnabled: Set the default state of spoken feedback on the login screen
                DeviceLoginScreenDefaultHighContrastEnabled: Set the default state of high contrast mode on the login screen
                DeviceLoginScreenDefaultVirtualKeyboardEnabled: Set default state of the on-screen keyboard on the login screen
                DeviceLoginScreenDefaultScreenMagnifierType: Set the default screen magnifier type enabled on the login screen
            #Android settings
                ArcEnabled: Enable ARC
                UnaffiliatedArcAllowed: Allow unaffiliated users to use ARC
                ArcPolicy: Configure ARC
                ArcAppInstallEventLoggingEnabled: Log events for Android app installs
                ArcBackupRestoreServiceEnabled: Control Android backup and restore service
                ArcGoogleLocationServicesEnabled: Control Android Google location services
                ArcCertificatesSyncMode: Set certificate availability for ARC-apps
                AppRecommendationZeroStateEnabled: Enable App Recommendations in Zero State of Search Box
            #Content Settings
                DefaultCookiesSetting: Default cookies setting
                DefaultImagesSetting: Default images setting
                DefaultJavaScriptSetting: Default JavaScript setting
                DefaultPluginsSetting: Default Flash setting
                DefaultPopupsSetting: Default popups setting
                DefaultNotificationsSetting: Default notification setting
                DefaultGeolocationSetting: Default geolocation setting
                DefaultMediaStreamSetting: Default mediastream setting
                DefaultWebBluetoothGuardSetting: Control use of the Web Bluetooth API
                DefaultWebUsbGuardSetting: Control use of the WebUSB API
                AutoSelectCertificateForUrls: Automatically select client certificates for these sites
                CookiesAllowedForUrls: Allow cookies on these sites
                CookiesBlockedForUrls: Block cookies on these sites
                CookiesSessionOnlyForUrls: Limit cookies from matching URLs to the current session
                ImagesAllowedForUrls: Allow images on these sites
                ImagesBlockedForUrls: Block images on these sites
                JavaScriptAllowedForUrls: Allow JavaScript on these sites
                JavaScriptBlockedForUrls: Block JavaScript on these sites
                PluginsAllowedForUrls: Allow the Flash plugin on these sites
                PluginsBlockedForUrls: Block the Flash plugin on these sites
                PopupsAllowedForUrls: Allow popups on these sites
                RegisteredProtocolHandlers: Register protocol handlers
                PopupsBlockedForUrls: Block popups on these sites
                NotificationsAllowedForUrls: Allow notifications on these sites
                NotificationsBlockedForUrls: Block notifications on these sites
                WebUsbAllowDevicesForUrls: Automatically grant permission to these sites to connect to USB devices with the given vendor and product IDs.
                WebUsbAskForUrls: Allow WebUSB on these sites
                WebUsbBlockedForUrls: Block WebUSB on these sites
            #Date and time
                SystemTimezone: Timezone
                SystemTimezoneAutomaticDetection: Configure the automatic timezone detection method
                SystemUse24HourClock: Use 24 hour clock by default
            #Default search provider
                DefaultSearchProviderEnabled: Enable the default search provider
                DefaultSearchProviderName: Default search provider name
                DefaultSearchProviderKeyword: Default search provider keyword
                DefaultSearchProviderSearchURL: Default search provider search URL
                DefaultSearchProviderSuggestURL: Default search provider suggest URL
                DefaultSearchProviderIconURL: Default search provider icon
                DefaultSearchProviderEncodings: Default search provider encodings
                DefaultSearchProviderAlternateURLs: List of alternate URLs for the default search provider
                DefaultSearchProviderImageURL: Parameter providing search-by-image feature for the default search provider
                DefaultSearchProviderNewTabURL: Default search provider new tab page URL
                DefaultSearchProviderSearchURLPostParams: Parameters for search URL which uses POST
                DefaultSearchProviderSuggestURLPostParams: Parameters for suggest URL which uses POST
                DefaultSearchProviderImageURLPostParams: Parameters for image URL which uses POST
            #Device update settings
                ChromeOsReleaseChannel: Release channel
                ChromeOsReleaseChannelDelegated: Users may configure the Chrome OS release channel
                DeviceAutoUpdateDisabled: Disable Auto Update
                DeviceAutoUpdateP2PEnabled: Auto update p2p enabled
                DeviceAutoUpdateTimeRestrictions: Update Time Restrictions
                DeviceTargetVersionPrefix: Target Auto Update Version
                DeviceUpdateStagingSchedule: The staging schedule for applying a new update
                DeviceUpdateScatterFactor: Auto update scatter factor
                DeviceUpdateAllowedConnectionTypes: Connection types allowed for updates
                DeviceUpdateHttpDownloadsEnabled: Allow autoupdate downloads via HTTP
                RebootAfterUpdate: Automatically reboot after update
                MinimumRequiredChromeVersion: Configure minimum allowed Chrome version for the device.
                DeviceRollbackToTargetVersion: Rollback to target version
                DeviceRollbackAllowedMilestones: Number of milestones rollback is allowed
                DeviceQuickFixBuildToken: Provide users with Quick Fix Build
            #Display
                DeviceDisplayResolution: Set display resolution and scale factor
                DisplayRotationDefault: Set default display rotation, reapplied on every reboot
            #Extensions
                ExtensionInstallBlacklist: Configure extension installation blacklist
                ExtensionInstallWhitelist: Configure extension installation whitelist
                ExtensionInstallForcelist: Configure the list of force-installed apps and extensions
                ExtensionInstallSources: Configure extension, app, and user script install sources
                ExtensionAllowedTypes: Configure allowed app/extension types
                ExtensionAllowInsecureUpdates: Allow insecure algorithms in integrity checks on extension updates and installs
                ExtensionSettings: Extension management settings
            #Google Assistant
                VoiceInteractionContextEnabled: "Allow Google Assistant to access screen context"
                VoiceInteractionHotwordEnabled: Allow Google Assistant to listen for the voice activation phrase
            #Google Cast
                EnableMediaRouter: Enable Google Cast
                ShowCastIconInToolbar: Show the Google Cast toolbar icon
            #Google Drive
                DriveDisabled: Disable Drive in the Google Chrome OS Files app
                DriveDisabledOverCellular: Disable Google Drive over cellular connections in the Google Chrome OS Files app
            #HTTP authentication
                AuthSchemes: Supported authentication schemes
                DisableAuthNegotiateCnameLookup: Disable CNAME lookup when negotiating Kerberos authentication
                EnableAuthNegotiatePort: Include non-standard port in Kerberos SPN
                AuthServerWhitelist: Authentication server whitelist
                AuthNegotiateDelegateWhitelist: Kerberos delegation server whitelist
                AuthNegotiateDelegateByKdcPolicy: Use KDC policy to delegate credentials.
                GSSAPILibraryName: GSSAPI library name
                AuthAndroidNegotiateAccountType: Account type for HTTP Negotiate authentication
                AllowCrossOriginAuthPrompt: Cross-origin HTTP Basic Auth prompts
                NtlmV2Enabled: Enable NTLMv2 authentication.
            #Kiosk settings
                DeviceLocalAccounts: Device-local accounts
                DeviceLocalAccountAutoLoginId: Device-local account for auto-login
                DeviceLocalAccountAutoLoginDelay: Device-local account auto-login timer
                DeviceLocalAccountAutoLoginBailoutEnabled: Enable bailout keyboard shortcut for auto-login
                DeviceLocalAccountPromptForNetworkWhenOffline: Enable network configuration prompt when offline
                AllowKioskAppControlChromeVersion: Allow the auto launched with zero delay kiosk app to control Google Chrome OS version
            #Legacy Browser Support
                AlternativeBrowserPath: Alternative browser to launch for configured websites.
                AlternativeBrowserParameters: Command-line parameters for the alternative browser.
                BrowserSwitcherChromePath: Path to Chrome for switching from the alternative browser.
                BrowserSwitcherChromeParameters: Command-line parameters for switching from the alternative browser.
                BrowserSwitcherDelay: Delay before launching alternative browser (milliseconds)
                BrowserSwitcherEnabled: Enable the Legacy Browser Support feature.
                BrowserSwitcherExternalSitelistUrl: URL of an XML file that contains URLs to load in an alternative browser.
                BrowserSwitcherKeepLastChromeTab: Keep last tab open in Chrome.
                BrowserSwitcherUrlList: Websites to open in alternative browser
                BrowserSwitcherUrlGreylist: Websites that should never trigger a browser switch.
                BrowserSwitcherUseIeSitelist: Use Internet Explorer's SiteList policy for Legacy Browser Support.
            #Linux container
                VirtualMachinesAllowed: Allow devices to run virtual machines on Chrome OS
                CrostiniAllowed: User is enabled to run Crostini
                DeviceUnaffiliatedCrostiniAllowed: Allow unaffiliated users to use Crostini
                CrostiniExportImportUIAllowed: User is enabled to export / import Crostini containers via the UI
            #Microsoft Active Directory management settings
                DeviceMachinePasswordChangeRate: Machine password change rate
                DeviceUserPolicyLoopbackProcessingMode: User policy loopback processing mode
                DeviceKerberosEncryptionTypes: Allowed Kerberos encryption types
                DeviceGpoCacheLifetime: GPO cache lifetime
                DeviceAuthDataCacheLifetime: Authentication data cache lifetime
            #Native Messaging
                NativeMessagingBlacklist: Configure native messaging blacklist
                NativeMessagingWhitelist: Configure native messaging whitelist
                NativeMessagingUserLevelHosts: Allow user-level Native Messaging hosts (installed without admin permissions)
            #Network File Shares settings
                NetworkFileSharesAllowed: Contorls Network File Shares for ChromeOS availability
                NetBiosShareDiscoveryEnabled: Controls Network File Share discovery via NetBIOS
                NTLMShareAuthenticationEnabled: Controls enabling NTLM as an authentication protocol for SMB mounts
                NetworkFileSharesPreconfiguredShares: List of preconfigured network file shares.
            #Network settings
                DeviceOpenNetworkConfiguration: Device-level network configuration
                DeviceDataRoamingEnabled: Enable data roaming
                NetworkThrottlingEnabled: Enable throttling network bandwidth
                DeviceHostnameTemplate: Device network hostname template
                DeviceWiFiFastTransitionEnabled: Enable 802.11r Fast Transition
                DeviceWiFiAllowed: Enable WiFi
                DeviceDockMacAddressSource: Device MAC address source when docked
            #Other
                UsbDetachableWhitelist: Whitelist of USB detachable devices
                DeviceAllowBluetooth: Allow bluetooth on device
                TPMFirmwareUpdateSettings: Configure TPM firmware update behavior
                DevicePolicyRefreshRate: Refresh rate for Device Policy
                DeviceBlockDevmode: Block developer mode
                DeviceAllowRedeemChromeOsRegistrationOffers: Allow users to redeem offers through Chrome OS Registration
                DeviceQuirksDownloadEnabled: Enable queries to Quirks Server for hardware profiles
                ExtensionCacheSize: Set Apps and Extensions cache size (in bytes)
                DeviceOffHours: Off hours intervals when the specified device policies are released
            #Password manager
                PasswordManagerEnabled: Enable saving passwords to the password manager
            #PluginVm
                PluginVmAllowed: Allow devices to use a PluginVm on Google Chrome OS
                PluginVmLicenseKey: PluginVm license key
                PluginVmImage: PluginVm image
            #Power and shutdown
                DeviceLoginScreenPowerManagement: Power management on the login screen
                UptimeLimit: Limit device uptime by automatically rebooting
                DeviceRebootOnShutdown: Automatic reboot on device shutdown
            #Power management
                ScreenDimDelayAC: Screen dim delay when running on AC power
                ScreenOffDelayAC: Screen off delay when running on AC power
                ScreenLockDelayAC: Screen lock delay when running on AC power
                IdleWarningDelayAC: Idle warning delay when running on AC power
                IdleDelayAC: Idle delay when running on AC power
                ScreenDimDelayBattery: Screen dim delay when running on battery power
                ScreenOffDelayBattery: Screen off delay when running on battery power
                ScreenLockDelayBattery: Screen lock delay when running on battery power
                IdleWarningDelayBattery: Idle warning delay when running on battery power
                IdleDelayBattery: Idle delay when running on battery power
                IdleAction: Action to take when the idle delay is reached
                IdleActionAC: Action to take when the idle delay is reached while running on AC power
                IdleActionBattery: Action to take when the idle delay is reached while running on battery power
                LidCloseAction: Action to take when the user closes the lid
                PowerManagementUsesAudioActivity: Specify whether audio activity affects power management
                PowerManagementUsesVideoActivity: Specify whether video activity affects power management
                PresentationScreenDimDelayScale: Percentage by which to scale the screen dim delay in presentation mode
                AllowWakeLocks: Allow wake locks
                AllowScreenWakeLocks: Allow screen wake locks
                UserActivityScreenDimDelayScale: Percentage by which to scale the screen dim delay if the user becomes active after dimming
                WaitForInitialUserActivity: Wait for initial user activity
                PowerManagementIdleSettings: Power management settings when the user becomes idle
                ScreenLockDelays: Screen lock delays
                PowerSmartDimEnabled: Enable smart dim model to extend the time until the screen is dimmed
                ScreenBrightnessPercent: Screen brightness percent
                DevicePowerPeakShiftBatteryThreshold: Set power peak shift battery threshold in percent
                DevicePowerPeakShiftDayConfig: Set power peak shift day config
                DevicePowerPeakShiftEnabled: Enable power peak shift
                DeviceBootOnAcEnabled: Enable boot on AC (alternating current)
                DeviceAdvancedBatteryChargeModeEnabled: Enable advanced battery charge mode
                DeviceAdvancedBatteryChargeModeDayConfig: Set advanced battery charge mode day config
                DeviceBatteryChargeMode: Battery charge mode
                DeviceBatteryChargeCustomStartCharging: Set battery charge custom start charging in percent
                DeviceBatteryChargeCustomStopCharging: Set battery charge custom stop charging in percent
                DeviceUsbPowerShareEnabled: Enable USB power share
            #Printing
                PrintingEnabled: Enable printing
                CloudPrintProxyEnabled: Enable Google Cloud Print proxy
                PrintingAllowedColorModes: Restrict printing color mode
                PrintingAllowedDuplexModes: Restrict printing duplex mode
                PrintingColorDefault: Default printing color mode
                PrintingDuplexDefault: Default printing duplex mode
                CloudPrintSubmitEnabled: Enable submission of documents to Google Cloud Print
                DisablePrintPreview: Disable Print Preview
                PrintHeaderFooter: Print Headers and Footers
                DefaultPrinterSelection: Default printer selection rules
                NativePrinters: Native Printing
                NativePrintersBulkConfiguration: Enterprise printer configuration file
                NativePrintersBulkAccessMode: Printer configuration access policy.
                NativePrintersBulkBlacklist: Disabled enterprise printers
                NativePrintersBulkWhitelist: Enabled enterprise printers
                DeviceNativePrinters: Enterprise printer configuration file for devices
                DeviceNativePrintersAccessMode: Device printers configuration access policy.
                DeviceNativePrintersBlacklist: Disabled enterprise device printers
                DeviceNativePrintersWhitelist: Enabled enterprise device printers
                PrintPreviewUseSystemDefaultPrinter: Use System Default Printer as Default
            #Proxy server
                ProxyMode: Choose how to specify proxy server settings
                ProxyServerMode: Choose how to specify proxy server settings
                ProxyServer: Address or URL of proxy server
                ProxyPacUrl: URL to a proxy .pac file
                ProxyBypassList: Proxy bypass rules
            #Quick unlock
                QuickUnlockModeWhitelist: Configure allowed quick unlock modes
                QuickUnlockTimeout: Set how often user has to enter password to use quick unlock
                PinUnlockMinimumLength: Set the minimum length of the lock screen PIN
                PinUnlockMaximumLength: Set the maximum length of the lock screen PIN
                PinUnlockWeakPinsAllowed: Enable users to set weak PINs for the lock screen PIN
            #Remote Attestation
                AttestationEnabledForDevice: Enable remote attestation for the device
                AttestationEnabledForUser: Enable remote attestation for the user
                AttestationExtensionWhitelist: Extensions allowed to to use the remote attestation API
                AttestationForContentProtectionEnabled: Enable the use of remote attestation for content protection for the device
            #Remote access
                RemoteAccessHostClientDomain: Configure the required domain name for remote access clients
                RemoteAccessHostClientDomainList: Configure the required domain names for remote access clients
                RemoteAccessHostFirewallTraversal: Enable firewall traversal from remote access host
                RemoteAccessHostDomain: Configure the required domain name for remote access hosts
                RemoteAccessHostDomainList: Configure the required domain names for remote access hosts
                RemoteAccessHostTalkGadgetPrefix: Configure the TalkGadget prefix for remote access hosts
                RemoteAccessHostRequireCurtain: Enable curtaining of remote access hosts
                RemoteAccessHostAllowClientPairing: Enable or disable PIN-less authentication for remote access hosts
                RemoteAccessHostAllowGnubbyAuth: Allow gnubby authentication for remote access hosts
                RemoteAccessHostAllowRelayedConnection: Enable the use of relay servers by the remote access host
                RemoteAccessHostUdpPortRange: Restrict the UDP port range used by the remote access host
                RemoteAccessHostMatchUsername: Require that the name of the local user and the remote access host owner match
                RemoteAccessHostTokenUrl: URL where remote access clients should obtain their authentication token
                RemoteAccessHostTokenValidationUrl: URL for validating remote access client authentication token
                RemoteAccessHostTokenValidationCertificateIssuer: Client certificate for connecting to RemoteAccessHostTokenValidationUrl
                RemoteAccessHostAllowUiAccessForRemoteAssistance: Allow remote users to interact with elevated windows in remote assistance sessions
                RemoteAccessHostAllowFileTransfer: Allow remote access users to transfer files to/from the host
            #Safe Browsing settings
                SafeBrowsingEnabled: Enable Safe Browsing
                SafeBrowsingExtendedReportingEnabled: Enable Safe Browsing Extended Reporting
                SafeBrowsingExtendedReportingOptInAllowed: Allow users to opt in to Safe Browsing extended reporting
                SafeBrowsingWhitelistDomains: Configure the list of domains on which Safe Browsing will not trigger warnings.
                PasswordProtectionWarningTrigger: Password protection warning trigger
                PasswordProtectionLoginURLs: Configure the list of enterprise login URLs where password protection service should capture fingerprint of password.
                PasswordProtectionChangePasswordURL: Configure the change password URL.
            #Sign-in settings
                DeviceGuestModeEnabled: Enable guest mode
                DeviceUserWhitelist: Login user white list
                DeviceAllowNewUsers: Allow creation of new user accounts
                DeviceLoginScreenDomainAutoComplete: Enable domain name autocomplete during user sign in
                DeviceShowUserNamesOnSignin: Show usernames on login screen
                DeviceWallpaperImage: Device wallpaper image
                DeviceEphemeralUsersEnabled: Wipe user data on sign-out
                LoginAuthenticationBehavior: Configure the login authentication behavior
                DeviceTransferSAMLCookies: Transfer SAML IdP cookies during login
                LoginVideoCaptureAllowedUrls: URLs that will be granted access to video capture devices on SAML login pages
                DeviceLoginScreenExtensions: Configure the list of installed apps on the login screen
                DeviceLoginScreenLocales: Device sign-in screen locale
                DeviceLoginScreenInputMethods: Device sign-in screen keyboard layouts
                DeviceSecondFactorAuthentication: Integrated second factor authentication mode
                DeviceLoginScreenIsolateOrigins: Enable Site Isolation for specified origins
                DeviceLoginScreenSitePerProcess: Enable Site Isolation for every site
                DeviceLoginScreenAutoSelectCertificateForUrls: Automatically select client certificates for these sites on the sign-in screen
            #Startup, Home page and New Tab page
                ShowHomeButton: Show Home button on toolbar
                HomepageLocation: Configure the home page URL
                HomepageIsNewTabPage: Use New Tab Page as homepage
                NewTabPageLocation: Configure the New Tab page URL
                RestoreOnStartup: Action on startup
                RestoreOnStartupURLs: URLs to open on startup
            #User and device reporting
                ReportDeviceVersionInfo: Report OS and firmware version
                ReportDeviceBootMode: Report device boot mode
                ReportDeviceUsers: Report device users
                ReportDeviceActivityTimes: Report device activity times
                ReportDeviceNetworkInterfaces: Report device network interfaces
                ReportDeviceHardwareStatus: Report hardware status
                ReportDeviceSessionStatus: Report information about active kiosk sessions
                ReportDeviceBoardStatus: Report board status
                ReportDevicePowerStatus: Report power status
                ReportDeviceStorageStatus: Report storage status
                ReportUploadFrequency: Frequency of device status report uploads
                ReportArcStatusEnabled: Report information about status of Android
                HeartbeatEnabled: Send network packets to the management server to monitor online status
                HeartbeatFrequency: Frequency of monitoring network packets
                LogUploadEnabled: Send system logs to the management server
                DeviceMetricsReportingEnabled: Enable metrics reporting
            #Wilco DTC
                DeviceWilcoDtcAllowed: Allows wilco diagnostics and telemetry controller
                DeviceWilcoDtcConfiguration: Wilco DTC configuration
            AbusiveExperienceInterventionEnforce: Abusive Experience Intervention Enforce
            AdsSettingForIntrusiveAdsSites: Ads setting for sites with intrusive ads
            AllowDeletingBrowserHistory: Enable deleting browser and download history
            AllowDinosaurEasterEgg: Allow Dinosaur Easter Egg Game
            AllowFileSelectionDialogs: Allow invocation of file selection dialogs
            AllowOutdatedPlugins: Allow running plugins that are outdated
            AllowPopupsDuringPageUnload: Allows a page to show popups during its unloading
            AllowScreenLock: Permit locking the screen
            AllowedDomainsForApps: Define domains allowed to access G Suite
            AllowedInputMethods: Configure the allowed input methods in a user session
            AllowedLanguages: Configure the allowed languages in a user session
            AlternateErrorPagesEnabled: Enable alternate error pages
            AlwaysOpenPdfExternally: Always Open PDF files externally
            ApplicationLocaleValue: Application locale
            AudioCaptureAllowed: Allow or deny audio capture
            AudioCaptureAllowedUrls: URLs that will be granted access to audio capture devices without prompt
            AudioOutputAllowed: Allow playing audio
            AutoFillEnabled: Enable AutoFill
            AutofillAddressEnabled: Enable AutoFill for addresses
            AutofillCreditCardEnabled: Enable AutoFill for credit cards
            AutoplayAllowed: Allow media autoplay
            AutoplayWhitelist: Allow media autoplay on a whitelist of URL patterns
            BackgroundModeEnabled: Continue running background apps when Google Chrome is closed
            BlockThirdPartyCookies: Block third party cookies
            BookmarkBarEnabled: Enable Bookmark Bar
            BrowserAddPersonEnabled: Enable add person in user manager
            BrowserGuestModeEnabled: Enable guest mode in browser
            BrowserNetworkTimeQueriesEnabled: Allow queries to a Google time service
            BrowserSignin: Browser sign in settings
            BuiltInDnsClientEnabled: Use built-in DNS client
            CaptivePortalAuthenticationIgnoresProxy: Captive portal authentication ignores proxy
            CertificateManagementAllowed: Allow users to manage installed certificates.
            CertificateTransparencyEnforcementDisabledForCas: Disable Certificate Transparency enforcement for a list of subjectPublicKeyInfo hashes
            CertificateTransparencyEnforcementDisabledForLegacyCas: Disable Certificate Transparency enforcement for a list of Legacy Certificate Authorities
            CertificateTransparencyEnforcementDisabledForUrls: Disable Certificate Transparency enforcement for a list of URLs
            ChromeCleanupEnabled: Enable Chrome Cleanup on Windows
            ChromeCleanupReportingEnabled: Control how Chrome Cleanup reports data to Google
            ChromeOsLockOnIdleSuspend: Enable lock when the device become idle or suspended
            ChromeOsMultiProfileUserBehavior: Control the user behavior in a multiprofile session
            CloudManagementEnrollmentMandatory: Enable mandatory cloud management enrollment
            CloudManagementEnrollmentToken: The enrollment token of cloud policy on desktop
            CloudPolicyOverridesPlatformPolicy: Google Chrome cloud policy overrides Platform policy.
            CommandLineFlagSecurityWarningsEnabled: Enable security warnings for command-line flags
            ComponentUpdatesEnabled: Enable component updates in Google Chrome
            ContextualSearchEnabled: Enable Tap to Search
            ContextualSuggestionsEnabled: Enable contextual suggestions of related web pages
            DataCompressionProxyEnabled: Enable the data compression proxy feature
            DefaultBrowserSettingEnabled: Set Google Chrome as Default Browser
            DefaultDownloadDirectory: Set default download directory
            DeveloperToolsAvailability: Control where Developer Tools can be used
            DeveloperToolsDisabled: Disable Developer Tools
            DeviceLocalAccountManagedSessionEnabled: Allow managed session on device
            DeviceRebootOnUserSignout: Force device reboot when user sign out
            DeviceScheduledUpdateCheck: Set custom schedule to check for updates
            Disable3DAPIs: Disable support for 3D graphics APIs
            DisableSafeBrowsingProceedAnyway: Disable proceeding from the Safe Browsing warning page
            DisableScreenshots: Disable taking screenshots
            DisabledPlugins: Specify a list of disabled plugins
            DisabledPluginsExceptions: Specify a list of plugins that the user can enable or disable
            DisabledSchemes: Disable URL protocol schemes
            DiskCacheDir: Set disk cache directory
            DiskCacheSize: Set disk cache size in bytes
            DownloadDirectory: Set download directory
            DownloadRestrictions: Allow download restrictions
            EasyUnlockAllowed: Allow Smart Lock to be used
            EcryptfsMigrationStrategy: Migration strategy for ecryptfs
            EditBookmarksEnabled: Enable or disable bookmark editing
            EnableDeprecatedWebPlatformFeatures: Enable deprecated web platform features for a limited time
            EnableOnlineRevocationChecks: Enable online OCSP/CRL checks
            EnableSyncConsent: Enable displaying Sync Consent during sign-in
            EnabledPlugins: Specify a list of enabled plugins
            EnterpriseHardwarePlatformAPIEnabled: Enables managed extensions to use the Enterprise Hardware Platform API
            ExternalStorageDisabled: Disable mounting of external storage
            ExternalStorageReadOnly: Treat external storage devices as read-only
            ForceBrowserSignin: Enable force sign in for Google Chrome
            ForceEphemeralProfiles: Ephemeral profile
            ForceGoogleSafeSearch: Force Google SafeSearch
            ForceMaximizeOnFirstRun: Maximize the first browser window on first run
            ForceNetworkInProcess: Force networking code to run in the browser process
            ForceSafeSearch: Force SafeSearch
            ForceYouTubeRestrict: Force minimum YouTube Restricted Mode
            ForceYouTubeSafetyMode: Force YouTube Safety Mode
            FullscreenAllowed: Allow fullscreen mode
            HardwareAccelerationModeEnabled: Use hardware acceleration when available
            HideWebStoreIcon: Hide the web store from the New Tab Page and app launcher
            Http09OnNonDefaultPortsEnabled: Enable HTTP/0.9 support on non-default ports
            ImportAutofillFormData: Import autofill form data from default browser on first run
            ImportBookmarks: Import bookmarks from default browser on first run
            ImportHistory: Import browsing history from default browser on first run
            ImportHomepage: Import of homepage from default browser on first run
            ImportSavedPasswords: Import saved passwords from default browser on first run
            ImportSearchEngine: Import search engines from default browser on first run
            IncognitoEnabled: Enable Incognito mode
            IncognitoModeAvailability: Incognito mode availability
            InstantTetheringAllowed: Allow Instant Tethering to be used.
            IsolateOrigins: Enable Site Isolation for specified origins
            IsolateOriginsAndroid: Enable Site Isolation for specified origins on Android devices
            JavascriptEnabled: Enable JavaScript
            KeyPermissions: Key Permissions
            MachineLevelUserCloudPolicyEnrollmentToken: The enrollment token of cloud policy on desktop
            ManagedBookmarks: Managed Bookmarks
            MaxConnectionsPerProxy: Maximal number of concurrent connections to the proxy server
            MaxInvalidationFetchDelay: Maximum fetch delay after a policy invalidation
            MediaCacheSize: Set media disk cache size in bytes
            MediaRouterCastAllowAllIPs: Allow Google Cast to connect to Cast devices on all IP addresses.
            MetricsReportingEnabled: Enable reporting of usage and crash-related data
            NTPContentSuggestionsEnabled: Show content suggestions on the New Tab page
            NetworkPredictionOptions: Enable network prediction
            NoteTakingAppsLockScreenWhitelist: Whitelist note-taking apps allowed on the Google Chrome OS lock screen
            OpenNetworkConfiguration: User-level network configuration
            OverrideSecurityRestrictionsOnInsecureOrigin: Origins or hostname patterns for which restrictions on insecure origins should not apply
            ParentAccessCodeConfig: Parent Access Code Configuration
            PinnedLauncherApps: List of pinned apps to show in the launcher
            PolicyDictionaryMultipleSourceMergeList: Allow merging dictionary policies from different sources
            PolicyListMultipleSourceMergeList: Allow merging list policies from different sources
            PolicyRefreshRate: Refresh rate for user policy
            PromotionalTabsEnabled: Enable showing full-tab promotional content
            PromptForDownloadLocation: Ask where to save each file before downloading
            ProxySettings: Proxy settings
            QuicAllowed: Allow QUIC protocol
            RelaunchHeadsUpPeriod: Set the time of the first user relaunch notification
            RelaunchNotification: Notify a user that a browser relaunch or device restart is recommended or required
            RelaunchNotificationPeriod: Set the time period for update notifications
            ReportCrostiniUsageEnabled: Report information about usage of Linux apps
            RequireOnlineRevocationChecksForLocalAnchors: Require online OCSP/CRL checks for local trust anchors
            RestrictAccountsToPatterns: Restrict accounts that are visible in Google Chrome
            RestrictSigninToPattern: Restrict which Google accounts are allowed to be set as browser primary accounts in Google Chrome
            RoamingProfileLocation: Set the roaming profile directory
            RoamingProfileSupportEnabled: Enable the creation of roaming copies for Google Chrome profile data
            RunAllFlashInAllowMode: Extend Flash content setting to all content
            SAMLOfflineSigninTimeLimit: Limit the time for which a user authenticated via SAML can log in offline
            SSLErrorOverrideAllowed: Allow proceeding from the SSL warning page
            SSLVersionMin: Minimum SSL version enabled
            SafeBrowsingForTrustedSourcesEnabled: Enable Safe Browsing for trusted sources
            SafeSitesFilterBehavior: Control SafeSites adult content filtering.
            SavingBrowserHistoryDisabled: Disable saving browser history
            SchedulerConfiguration: Select task scheduler configuration
            SearchSuggestEnabled: Enable search suggestions
            SecondaryGoogleAccountSigninAllowed: Allow Multiple Sign-in Within the Browser
            SecurityKeyPermitAttestation: URLs/domains automatically permitted direct Security Key attestation
            SessionLengthLimit: Limit the length of a user session
            SessionLocales: Set the recommended locales for a managed session
            ShelfAutoHideBehavior: Control shelf auto-hiding
            ShowAppsShortcutInBookmarkBar: Show the apps shortcut in the bookmark bar
            ShowLogoutButtonInTray: Add a logout button to the system tray
            SignedHTTPExchangeEnabled: Enable Signed HTTP Exchange (SXG) support
            SigninAllowed: Allow sign in to Google Chrome
            SitePerProcess: Enable Site Isolation for every site
            SitePerProcessAndroid: Enable Site Isolation for every site
            SmartLockSigninAllowed: Allow Smart Lock Signin to be used.
            SmsMessagesAllowed: Allow SMS Messages to be synced from phone to Chromebook.
            SpellCheckServiceEnabled: Enable or disable spell checking web service
            SpellcheckEnabled: Enable spellcheck
            SpellcheckLanguage: Force enable spellcheck languages
            SpellcheckLanguageBlacklist: Force disable spellcheck languages
            StartupBrowserWindowLaunchSuppressed: Suppress launching of browser window
            SuppressUnsupportedOSWarning: Suppress the unsupported OS warning
            SyncDisabled: Disable synchronization of data with Google
            TabLifecyclesEnabled: Enables or disables tab lifecycles
            TaskManagerEndProcessEnabled: Enable ending processes in Task Manager
            TermsOfServiceURL: Set the Terms of Service for a device-local account
            ThirdPartyBlockingEnabled: Enable third party software injection blocking
            TouchVirtualKeyboardEnabled: Enable virtual keyboard
            TranslateEnabled: Enable Translate
            URLBlacklist: Block access to a list of URLs
            URLWhitelist: Allow access to a list of URLs
            UnifiedDesktopEnabledByDefault: Make Unified Desktop available and turn on by default
            UnsafelyTreatInsecureOriginAsSecure: Origins or hostname patterns for which restrictions on insecure origins should not apply
            UrlKeyedAnonymizedDataCollectionEnabled: Enable URL-keyed anonymized data collection
            UsageTimeLimit: Time Limit
            UserAvatarImage: User avatar image
            UserDataDir: Set user data directory
            UserDisplayName: Set the display name for device-local accounts
            VideoCaptureAllowed: Allow or deny video capture
            VideoCaptureAllowedUrls: URLs that will be granted access to video capture devices without prompt
            VpnConfigAllowed: Allow the user to manage VPN connections
            WPADQuickCheckEnabled: Enable WPAD optimization
            WallpaperImage: Wallpaper image
            WebAppInstallForceList: Configure list of force-installed Web Apps
            WebDriverOverridesIncompatiblePolicies: Allow WebDriver to Override Incompatible Policies
            WebRtcEventLogCollectionAllowed: Allow collection of WebRTC event logs from Google services
            WebRtcUdpPortRange: Restrict the range of local UDP ports used by WebRTC
            WelcomePageOnOSUpgradeEnabled: Enable showing the welcome page on the first browser launch following OS upgrade
