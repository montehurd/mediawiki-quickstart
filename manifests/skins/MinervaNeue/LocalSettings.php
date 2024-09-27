<?php

wfLoadSkin( 'MinervaNeue' );

# HAX: for some reason MinervaNeue can't by loaded by using its name.
# QuickStart's installer use skins' names. This hack just overrides the
# actual name with "Minerva" without requiring the installer to have
# knowledge of this bug
if (isset($wgDefaultSkin) && $wgDefaultSkin === 'MinervaNeue') {
    $wgDefaultSkin = 'Minerva';
}
