<?php

/**
 * Implements hook_form().
 *
 * flat_nextcloud admin menu which can be used to adapt the default settings.
 *
 */
function flat_nextcloud_admin_form($form, &$form_state)
{
    $config = variable_get('flat_nextcloud',array());

    $form = array();

    $form['overview'] = array(
        '#markup' => t('Configure local Nextcloud instance settings for user data upload. Nextcloud needs to run on the same server as this Drupal installation'),
        '#prefix' => '<p>',
        '#suffix' => '</p>',);

    $form['nextcloud'] = array(
        '#type' => 'fieldset',
        '#title' => t('Nextcloud settings'),
        '#tree' => TRUE,
        );


    $form['nextcloud']['activated'] = array (
        '#title' => t('Use Nextcloud'),
        '#description' => t('Use Nextcloud for data upload '),
        '#type' => 'checkbox',
        '#default_value' => $config['activated'],
        '#required' => FALSE);


    $form['nextcloud']['admin_name'] = array (
        '#type' => 'textfield',
        '#title' => 'Nextcloud admin name',
        '#description' => t('Nextcloud admin user name'),
        '#default_value' => $config['admin_name'],
        '#required' => TRUE,);

    $form['nextcloud']['admin_pass'] = array (
        '#type' => 'password',
        '#title' => 'Nextcloud admin password',
        '#description' => t('Nextcloud admin user password'),
        '#default_value' => $config['admin_pass'],
        '#required' => FALSE,);

    $form['nextcloud']['schema'] = array (
        '#type' => 'textfield',
        '#title' => 'Host schema',
        '#description' => t('HTTP or HTTPS'),
        '#default_value' => $config['schema'],
        '#required' => TRUE,);

    $form['nextcloud']['host'] = array (
        '#type' => 'textfield',
        '#title' => 'Host name',
        '#description' => t('IP address or hostname'),
        '#default_value' => $config['host'],
        '#required' => TRUE,);

    $form['nextcloud']['root_dir'] = array (
        '#type' => 'textfield',
        '#title' => 'Nextcloud root directory',
        '#description' => t('Nextcloud installation path'),
        '#default_value' => $config['root_dir'],
        '#required' => TRUE,);

    $form['nextcloud']['data_dir'] = array (
        '#type' => 'textfield',
        '#title' => 'Nextcloud data directory',
        '#description' => t('Directory where Nextcloud stores uploaded user data'),
        '#default_value' => $config['data_dir'],
        '#required' => TRUE,);

    $form['button']['submit'] = array (
        '#type' => 'submit',
        '#value' => t('Save'),
        '#submit' => array(
            'keep_default_password',
            'flat_nextcloud_admin_form_submit',
        )
    );


    $form['button']['restore'] = array (
        '#type' => 'submit',
        '#value' => t('Reset to defaults'),
    );

    $form['button']['check'] = array (
        '#type' => 'submit',
        '#value' => t('Check nextcloud connection'),);

    return $form;
}

/**
 * keeps the default password in case no password has been entered
 */
function keep_default_password($form, &$form_state) {


    if (empty($form_state['values']['nextcloud']['admin_pass'])) {
        $form_state['values']['nextcloud']['admin_pass'] = variable_get('flat_nextcloud')['admin_pass'];
    }

}

/**
 * function call to check if nextcloud is reachable using the nextcloud command line tool (occ).
 *
 *
 * @return array|bool if successfully status of occ otherwise FALSE
 */
function check_nextcloud_status()
{
    $status = FALSE;

    $config = variable_get('flat_nextcloud');

    $cmd = $config['root_dir'] . '/occ status --output=json';
    exec($cmd, $output, $return_val);

    if (!$return_val) {
        $formatted = (array)json_decode($output[0]);

        if ($formatted['installed']){
            return $formatted;
        }

    }

    return $status;
}


/**
 * function call to check if nextcloud external files extension (files_external app) is enabled using the nextcloud command line tool (occ).
 *
 * @param $enable bool If true function tries to enable the extension
 *
 * @return bool
 */
function nextcloud_external_files_plugin_enabled($enable=FALSE)
{
    $enabled = FALSE;


    // occ needs to be called from nextcloud root directory as apache user
    $config = variable_get('flat_nextcloud');

    $cmd = $config['root_dir'] . '/occ app:list --output=json';
    exec ( $cmd , $output, $return_val);

    // In case of positive return value (0 = no errors), check on shell output the status of the plugin
    if (!$return_val) {

        $formatted = (array)json_decode($output[0]);

        // in case bool is set and plugin is disabled, enable the plugin and rerun listing of plugin status
        if (array_key_exists('files_external', $formatted['disabled']) AND $enable) {

            $cmd = $config['root_dir'] . '/occ app:enable files_external';
            exec($cmd, $output, $return_val);

            $cmd = $config['root_dir'] . '/occ app:list --output=json';
            exec ( $cmd , $output, $return_val);

            if ($output) {
                $formatted = (array)json_decode($output[0]);

            }
        }

        if (array_key_exists('files_external', $formatted['enabled'])) {
            $enabled = TRUE;
        }
    }

    return $enabled;
}



function flat_nextcloud_admin_form_validate ($form, &$form_state)
{
    $button = $form_state['values']['op'];

    switch ($button) {
        case 'Save': {

            break;
        }

        case 'Reset to defaults': {
            break;
        }

        case 'Check nextcloud connection': {
            $status = check_nextcloud_status();

            if (!$status) {
                form_set_error('activated', 'Nextcloud status check failed');

            } else {
                $form_state['values']['status'] = $status;
            }

            break;
        }
    }

    return $form;
}


function flat_nextcloud_admin_form_submit ($form, &$form_state)
{
    $button = $form_state['values']['op'];

    switch ($button) {
        case 'Save': {
            module_load_include('inc', 'flat_nextcloud', 'inc/config');

            flat_nextcloud_set_nextcloud($form_state['values']['nextcloud']);

            drupal_set_message(t('Changed values have been saved'));

            break;
        }

        case 'Reset to defaults': {

            module_load_include('inc', 'flat_nextcloud', 'inc/config');

            flat_nextcloud_set_nextcloud();

            drupal_set_message(t('Nextcloud settings have been reset to default'));

            break;
        }

        case 'Check nextcloud connection': {

            drupal_set_message('Passed Nextcloud connection check');


            break;
        }
    }


}
