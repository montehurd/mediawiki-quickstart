<?php

/**
 * Maintenance script to check if a specific extension or skin is enabled.
 *
 * Usage:
 *   php maintenance/run.php isComponentEnabled --component=ExtensionName --type=extensions
 *   php maintenance/run.php isComponentEnabled --component=SkinName --type=skins
 */

require_once __DIR__ . '/Maintenance.php';

use MediaWiki\MediaWikiServices;

class IsComponentEnabled extends Maintenance {
    public function __construct() {
        parent::__construct();
        $this->addDescription('Checks if a specified component (extension or skin) is enabled.');
        $this->addOption('component', 'The component to check', true, true);
        $this->addOption('type', 'The type of component (extensions or skins)', true, true);
    }

    public function execute() {
        $componentName = $this->getOption('component');
        $componentType = strtolower($this->getOption('type'));

        if ($componentType === 'extensions') {
            // Check if the extension is loaded
            $isEnabled = \ExtensionRegistry::getInstance()->isLoaded($componentName);
        } elseif ($componentType === 'skins') {
            // Retrieve the list of enabled skins using SkinFactory
            $services = MediaWikiServices::getInstance();
            $skinFactory = $services->getSkinFactory();
            $enabledSkins = $skinFactory->getSkinNames();

            // Convert both the component name and enabled skins to lowercase
            $componentNameLower = strtolower($componentName);
            $enabledSkinsLower = array_map('strtolower', $enabledSkins);

            // Check if the specified skin is in the list of enabled skins
            $isEnabled = in_array($componentNameLower, $enabledSkinsLower, true);
        } else {
            $this->fatalError("Unknown component type: $componentType. Please specify 'extensions' or 'skins'.");
            return;
        }

        $this->output($isEnabled ? "1" : "0");
    }
}

$maintClass = IsComponentEnabled::class;
require_once RUN_MAINTENANCE_IF_MAIN;
