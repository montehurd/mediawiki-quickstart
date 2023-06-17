<?php

require_once __DIR__ . '/Maintenance.php';

class isExtensionEnabled extends Maintenance {
    public function __construct() {
        parent::__construct();
        $this->addOption( 'extension', 'The extension to check', true, true );
    }

    public function execute() {
        $extension = $this->getOption( 'extension' );
        $normalizedExtension = $this->normalizeExtensionName($extension);
        $loadedExtensions = $this->getAllNormalizedLoadedExtensions();
        if (in_array($normalizedExtension, $loadedExtensions)) {
            $this->output(1);
        } else {
            $this->output(0);
        }
    }

    private function normalizeExtensionName($extension) {
        return strtolower(str_replace(' ', '', $extension));
    }

    private function getAllNormalizedLoadedExtensions() {
        $registry = ExtensionRegistry::getInstance();
        $loadedExtensions = array_keys($registry->getAllThings());
        return array_map([$this, 'normalizeExtensionName'], $loadedExtensions);
    }
}

$maintClass = isExtensionEnabled::class;
require_once RUN_MAINTENANCE_IF_MAIN;