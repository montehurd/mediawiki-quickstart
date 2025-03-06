<?php

$wgMinervaOverflowInPageActions = [
    "base" => false,
    "beta" => false,
    "amc" => true,
    "loggedin" => true
];

$wgVectorAppearance = [
	'logged_in' => true,
	'logged_out' => true,
	'beta' => true
];

// Add CSS from the WikimediaMessages repo to the following skins.
$wgWikimediaStylesSkins = [ "vector-2022", "minerva" ];

# InstantCommons allows wiki to use images from https://commons.wikimedia.org
$wgUseInstantCommons = true;

$wgSitename = "mediawiki";
$wgMetaNamespace = "Mediawiki";

$wgEmergencyContact = "apache@localhost";
$wgPasswordSender = "apache@localhost";

$wgDBprefix = "";

$wgMFAmcOutreachMinEditCount = 0;
$wgMFAmcOutreach = true;

// Use production bundle of Vue to silence noisy warnings in console.
$wgVueDevelopmentMode = false;


// Disable ULS IME keyboard tool.
// This leads to false positives in tests and is not a feature maintained by web team.
$wgULSIMEEnabled = false;


const QS_ANSWERS_MULTI_CHOICE =  [
	[
		'label' => 'ext-quicksurveys-example-internal-survey-answer-positive',
		'freeformTextLabel' => 'ext-quicksurveys-example-internal-survey-freeform-text-label',
	],
	[
		'label' => 'ext-quicksurveys-example-internal-survey-answer-neutral',
		'freeformTextLabel' => 'ext-quicksurveys-example-internal-survey-freeform-text-label',
	],
	[
		'label' => 'ext-quicksurveys-example-internal-survey-answer-negative',
		'freeformTextLabel' => 'ext-quicksurveys-example-internal-survey-freeform-text-label',
	],
];

// Applies to all surveys
const QS_DEFAULTS = [
	// Who is the survey for? All fields are optional.
	'audience' => [
		'minEdits' => 0,
		'anons' => false,
		'maxEdits' => 500,
		'registrationStart' => '2018-01-01',
		'registrationEnd' => '2080-01-31',
		// You must have CentralNotice extension installed in order to limit audience by country
		// 'countries' => [ 'US', 'UK' ]
	],
	// The i18n key of the privacy policy text
	'privacyPolicy' => 'ext-quicksurveys-example-external-survey-privacy-policy',
	// Whether the survey is enabled
	'enabled' => true,
	'shuffleAnswersDisplay' => false,
	// Percentage of users that will see the survey
	'coverage' => 0,
	// For each platform (desktop, mobile), which version of it is targeted
	'platforms' => [
		'desktop' => [ 'stable' ],
		'mobile' => [ 'stable' ]
	],
];

$wgQuickSurveysConfig = [
	// Example of an internal survey
	[
		// Survey name
		'name' => 'internal example survey',
		// Internal or external link survey?
		'type' => 'internal',
		// Survey question message key
		'questions' => [
			[
				'name' => 'q1',
				'question' => 'ext-quicksurveys-example-internal-survey-question',
				// The respondent can choose one answer from a list.
				'layout' => 'single-answer',
				// The message key of the description of the survey. Displayed immediately below the survey question.
				//'description' => 'ext-quicksurveys-example-internal-survey-description',
				// Possible answer message keys for positive, neutral, and negative
				'answers' => QS_ANSWERS_MULTI_CHOICE,
			]
		],
	] + QS_DEFAULTS,

	[
		// Survey name
		'name' => 'internal multi answer example survey',
		// Internal or external link survey?
		'type' => 'internal',
		// Survey question message key
		'questions' => [
			[
				'name' => 'q1',
				'layout' => 'multiple-answer',
				'question' => 'ext-quicksurveys-example-internal-survey-question',
				'answers' => QS_ANSWERS_MULTI_CHOICE,
			]
		],
	] + QS_DEFAULTS,
	// Example of an external survey
	[
		'name' => 'external example survey',
		// Internal or external link survey
		'type' => 'external',
		// Survey question message key
		'questions' => [
			[
				'name' => 'q1',
				'question' => 'ext-quicksurveys-example-external-survey-question',
				'description' => 'ext-quicksurveys-example-external-survey-description',
				'link' => 'ext-quicksurveys-example-external-survey-link',
				'instanceTokenParameterName' => 'parameterName',
			]
		],
	] + QS_DEFAULTS,
];


// The following CSS overrides can be used to "vet" changes by forcing Pixel to
// apply additional styles to match expectations.
$wgHooks['BeforePageDisplay'][] = function ( $out ) {
	$css = <<<HTML
<style type="text/css">
	/* Popup notifications are hidden in visual regression suite as they can appear unpredictably. */
	.vector-popup-notification { display: none !important; }
</style>
HTML;
	$out->addHTML( $css );
};


$wgVectorLanguageAlertInSidebar = [
	"logged_in" => true,
	"logged_out" => true
];


// Campaign events settings
$wgCampaignEventsEnableEventInvitation = true;
$wgCampaignEventsShowEventInvitationSpecialPages = true;

$wgGroupPermissions['user']['campaignevents-enable-registration'] = true;
$wgGroupPermissions['user']['campaignevents-delete-registration'] = true;
$wgGroupPermissions['user']['campaignevents-organize-events'] = true;
$wgGroupPermissions['user']['campaignevents-send-email'] = true;
$wgGroupPermissions['organizer']['campaignevents-enable-registration'] = true;
$wgGroupPermissions['organizer']['campaignevents-delete-registration'] = true;
$wgGroupPermissions['organizer']['campaignevents-organize-events'] = true;
$wgGroupPermissions['organizer']['campaignevents-send-email'] = true;

$wgCampaignEventsEnableEventWikis = true;


# Universal Language Selector
$wgULSPosition = 'interlanguage';
$wgULSCompactLanguageLinksBetaFeature = false;

# Useful when testing language variants
$wgUsePigLatinVariant = true;


// $wgParserEnableLegacyHeadingDOM = false;


# -------------

$wgAPIMaxResultSize = 327680;


$wgLogos = [
	'icon' => 'https://en.wikipedia.org/static/images/icons/wikipedia.png',
	'tagline' => [
		'src' => 'https://en.wikipedia.org/static/images/mobile/copyright/wikipedia-tagline-en.svg',
		'width' => 117,
		'height' => 13,
	],
	'1x' => 'https://en.wikipedia.org/static/images/project-logos/enwiki.png',
	'2x' => 'https://en.wikipedia.org/static/images/project-logos/enwiki-2x.png',
	'wordmark' => [
		'src' => 'https://en.wikipedia.org/static/images/mobile/copyright/wikipedia-wordmark-en.svg',
		'width' => 119,
		'height' => 18,
	],
];

$wgExtendedLoginCookieExpiration = 0;

$wgLocalisationCacheConf = [
  'class' => LocalisationCache::class,
  'store' => 'detect',
  'storeClass' => false,
  'storeDirectory' => false,
  'storeServer' => [],
  'forceRecache' => false,
  'manualRecache' => false,
];

$PARSOID_INSTALL_DIR = 'vendor/wikimedia/parsoid'; # bundled copy

// For developers: ensure Parsoid is executed from $PARSOID_INSTALL_DIR,
// (not the version included in mediawiki-core by default)
// Must occur *before* wfLoadExtension()
if ( $PARSOID_INSTALL_DIR !== 'vendor/wikimedia/parsoid' ) {
    AutoLoader::$psr4Namespaces += [
        // Keep this in sync with the "autoload" clause in
        // $PARSOID_INSTALL_DIR/composer.json
        'Wikimedia\\Parsoid\\' => "$PARSOID_INSTALL_DIR/src",
    ];
}

wfLoadExtension( 'Parsoid', "$PARSOID_INSTALL_DIR/extension.json" );

# Manually configure Parsoid
$wgVisualEditorParsoidAutoConfig = false;
$wgParsoidSettings = [
    'useSelser' => true,
    'rtTestMode' => false,
    'linting' => false,
];

$wgVirtualRestConfig['modules']['parsoid'] = [
    'url' => "http://mediawiki-web:8080" . $wgScriptPath . '/rest.php',
];

$wgThanksSendToBots = true;

$wgPopupsGateway = 'restbaseHTML';
$wgPopupsRestGatewayEndpoint = 'https://en.wikipedia.org/api/rest_v1/page/summary/';

$wgFragmentMode = [ 'html5', 'legacy' ];

$wgParserEnableLegacyHeadingDOM = false;



$wgGEConfirmEmailEnabled = false;

$wgGEHelpPanelEnabled = false;
