<?php

/**
 * Maintenance script to filter out installed components from a provided list.
 *
 * Usage:
 *   php maintenance/run.php FilterOutInstalledComponents --components "skins/Vector extensions/IPInfo skins/Timeless extensions/Math"
 */

require_once '/var/www/html/w/maintenance/Maintenance.php';

use MediaWiki\MediaWikiServices;

class FilterOutInstalledComponents extends Maintenance {
    private $extensionRegistry;
    private $installedSkins = null;
    private $skinPaths = null;

    public function __construct() {
        parent::__construct();
        $this->addDescription('Returns only components that are NOT installed from a provided list.');
        $this->addOption('components', 'Space-separated list of components in format "type/Name"', true, true);
    }

    public function execute() {
        $componentsStr = $this->getOption('components');
        $components = preg_split('/\s+/', trim($componentsStr));

        // Initialize once
        $this->extensionRegistry = \ExtensionRegistry::getInstance();

        $nonInstalledComponents = [];

        foreach ($components as $component) {
            if (!$this->isComponentInstalled($component)) {
                $nonInstalledComponents[] = $component;
            }
        }

        $this->output(implode(' ', $nonInstalledComponents));
    }

    private function isComponentInstalled($component) {
        // Split component into type and name
        $parts = explode('/', $component, 2);
        if (count($parts) !== 2) {
            return false;
        }

        $type = strtolower($parts[0]);
        $name = $parts[1];

        if ($type === 'extensions') {
            return $this->extensionRegistry->isLoaded($name);
        } elseif ($type === 'skins') {
            // Lazy-load installed skins list only once
            if ($this->installedSkins === null) {
                $skinFactory = MediaWikiServices::getInstance()->getSkinFactory();
                $skinPaths = $this->extensionRegistry->getAttribute('SkinLessImportPaths');

                // Store the paths and installed skins
                $this->skinPaths = $skinPaths;
                $this->installedSkins = array_map('strtolower', array_keys($skinFactory->getInstalledSkins()));
            }

            // Check if the name matches any registered skin (case-insensitive)
            if (in_array(strtolower($name), $this->installedSkins, true)) {
                return true;
            }

            // Check if any path contains our skin directory
            $searchPath = "/var/www/html/w/skins/{$name}";
            foreach ($this->skinPaths as $path) {
                if (strpos($path, $searchPath) !== false) {
                    return true;
                }
            }
        
            return false;
        }

        return false;
    }
}

$maintClass = FilterOutInstalledComponents::class;
require_once RUN_MAINTENANCE_IF_MAIN;