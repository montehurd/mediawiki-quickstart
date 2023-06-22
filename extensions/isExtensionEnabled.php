<?php

require_once __DIR__ . '/Maintenance.php';

class isExtensionEnabled extends Maintenance {
    public function __construct() {
        parent::__construct();
        $this->addOption( 'extension', 'The extension to check', true, true );
    }

    public function execute() {
        $this->output(in_array($this->normalizeExtensionName($this->getOption('extension')), $this->getAllNormalizedLoadedExtensions()) ? 1 : 0);
    }

    private function normalizeExtensionName($extension) {
        return strtolower(str_replace(' ', '', $extension));
    }

    private function getAllNormalizedLoadedExtensions() {
        return array_map([$this, 'normalizeExtensionName'], array_keys(ExtensionRegistry::getInstance()->getAllThings()));
    }
}

$maintClass = isExtensionEnabled::class;
require_once RUN_MAINTENANCE_IF_MAIN;
