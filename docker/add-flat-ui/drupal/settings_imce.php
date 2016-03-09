#!/usr/bin/env drush
<?php

$profiles = variable_get('imce_profiles', array());

$new_profile = array(
 'name' => "Custom",
 'usertab' => 1,
 'filesize' => "0",
 'quota' => "2",
 'tuquota' => "10",
 'extensions' => "*",
 'dimensions' => "1200x1200",
 'filenum' => "0",
 'directories' => array(
  '0' => array(
   'name' => "php: return 'users/'.\$user->name;",
   'subnav' => 1,
   'browse' => 1,
   'upload' => 1,
   'thumb' => 0,
   'delete' => 1,
   'resize' => 0),
  '1' => array(
   'name' => "",
   'subnav' => 0,
   'browse' => 0,
   'upload' => 0,
   'thumb' => 0,
   'delete' => 0,
   'resize' => 0),
  '2' => array(
   'name' => "",
   'subnav' => 0,
   'browse' => 0,
   'upload' => 0,
   'thumb' => 0,
   'delete' => 0,
   'resize' => 0),
   ),
 'thumbnails' => array(
  '0' => array(
   'name' => "Small",
   'dimensions' => "90x90",
   'prefix' => "small_",
   'suffix' => ""),
  '1' => array(
   'name' => "Medium",
   'dimensions' => "120x120",
   'prefix' => "medium_",
   'suffix' => ""),
  '2' => array(
   'name' => "Large",
   'dimensions' => "180x180",
   'prefix' => "large_",
   'suffix' => ""),
  '3' => array(
   'name' => "",
   'dimensions' => "",
   'prefix' => "",
   'suffix' => ""),
  '4' => array(
   'name' => "",
   'dimensions' => "",
   'prefix' => "",
   'suffix' => ""),
   ),
);

$profiles['2'] = $new_profile;
variable_set('imce_profiles', $profiles);

$roles = array (
  '3' => array(
    'public_pid' => "2"),
  '2' => array(
    'public_pid' => "2"),
  '1' => array(
    'public_pid' => 0),
  );

variable_set('imce_roles_profiles', $roles);
