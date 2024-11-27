<?php

wfLoadSkin( 'Vector' );

# HAX: for some reason Vector can't by loaded by using its name.
# QuickStart's installer use skins' names. This hack just overrides the
# actual name with "Vector" without requiring the installer to have
# knowledge of this bug
if (isset($wgDefaultSkin) && $wgDefaultSkin === 'Vector') {
    $wgDefaultSkin = 'vector-2022';
}
