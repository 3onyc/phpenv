#!/bin/bash

echo "Installing Pyrus..."

if [ -n "$PHPENV_USE_PYRUS_EXPERIMENTAL" ]; then
    pyrus_url="https://github.com/pyrus/Pyrus/raw/master/pyrus.phar"
else
    pyrus_url="http://pear2.php.net/pyrus.phar"
fi

wget -qP "$OUTPUT_DIR/bin" $pyrus_url

if [ ! -d "$OUTPUT_DIR/pear" ]; then
    mkdir "$OUTPUT_DIR/pear"
fi

pyrus_home="$OUTPUT_DIR/share/pear"

# Create Pyrus' own Home Directory
# so it will not place them in the real user's home directory
if [ ! -d "$pyrus_home" ]; then
    mkdir -p "$pyrus_home"
fi

# Add the directory where the PHP Files of PEAR Packages get installed
# to PHP's include path
echo "include_path=.:$OUTPUT_DIR/pear/php" > "$OUTPUT_DIR/etc/conf.d/pear.ini"

# Create the Pyrus executable
#
pyrus_sh="$OUTPUT_DIR/bin/pyrus"

echo "#!/bin/bash" > $pyrus_sh

# Pyrus looks for its config by default in the User's Home Directory,
# so define a separate Home Directory just for Pyrus to isolate
# the Configs between PHP versions
echo "export HOME=$pyrus_home" >> $pyrus_sh
echo "$OUTPUT_DIR/bin/php -dphar.readonly=0 $OUTPUT_DIR/bin/pyrus.phar \$*" >> $pyrus_sh

chmod +x "$OUTPUT_DIR/bin/pyrus"

# Setup Pyrus to place executables in the version's bin directory
# so executables can be later easier collected on rehash
pear_sysconfig=$(cat <<EOF
<?xml version="1.0"?>
<pearconfig version="1.0">
    <bin_dir>$OUTPUT_DIR/bin</bin_dir>
</pearconfig>
EOF
)

echo "$pear_sysconfig" > "$OUTPUT_DIR/pear/.config"

# Create the default pearconfig.xml by hand, otherwise the
# User would be asked for the PEAR path on the first run.
pear_config=$(cat <<EOF
<?xml version="1.0"?>
<pearconfig version="1.0">
    <default_channel>pear2.php.net</default_channel>
    <auto_discover>0</auto_discover>
    <http_proxy></http_proxy>
    <cache_dir>$OUTPUT_DIR/pear/cache</cache_dir>
    <temp_dir>$OUTPUT_DIR/pear/temp</temp_dir>
    <verbose>1</verbose>
    <preferred_state>stable</preferred_state>
    <umask>0022</umask>
    <cache_ttl>3600</cache_ttl>
    <my_pear_path>$OUTPUT_DIR/pear</my_pear_path>
    <plugins_dir>$OUTPUT_DIR/share/pear/.pear</plugins_dir>
</pearconfig>
EOF
)

if [ ! -d "$pyrus_home/.pear" ]; then
    mkdir "$pyrus_home/.pear"
fi

echo $pear_config > "$pyrus_home/.pear/pearconfig.xml"

echo Done.
