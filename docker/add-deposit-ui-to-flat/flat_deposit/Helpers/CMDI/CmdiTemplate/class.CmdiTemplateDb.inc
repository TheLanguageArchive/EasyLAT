<?php

class CmdiTemplateDb
{
    /**
     * Fetching all templates
     *
     * @param string $filename
     * @param int    $uid user id
     *
     * @return boolean
     */
    public static function all($profile, $uid)
    {
        return db_select('flat_cmdi_templates', 'fct')
                ->fields('fct')
                ->condition('profile', $profile, '=')
                ->condition('uid', $uid, '=')
                ->execute()
                ->fetchAllAssoc('id', PDO::FETCH_ASSOC);
    }

    /**
     * Fetching specific template
     *
     * @param string $id
     * @param int    $uid user id
     *
     * @return boolean
     */
    public static function fetch($id, $uid)
    {
        return db_select('flat_cmdi_templates', 'fct')
                ->fields('fct')
                ->condition('id', $id, '=')
                ->condition('uid', $uid, '=')
                ->execute()
                ->fetchAssoc('id', PDO::FETCH_ASSOC);
    }

    /**
     * check if label for component already exists
     *
     * @param string $profile
     * @param string $label
     * @param string $component_id
     * @param string $uid
     *
     * @return boolean
     */
    public static function exists($profile, $label, $component_id, $uid)
    {
        try {

            $result = db_select('flat_cmdi_templates', 'fct')
                ->fields('fct', ['id'])
                ->condition('profile', $profile)
                ->condition('label', $label)
                ->condition('component_id', $component_id)
                ->condition('uid', $uid)
                ->countQuery()
                ->execute()
                ->fetchField();

            return intval($result) > 0;

        } catch (Exception $e) {

            static::error($e);
            return false;
        }
    }

    /**
     * save cmdi template block to db
     *
     * @param string $profile
     * @param string $label
     * @param string $component_id
     * @param string $block
     * @param string $uid
     *
     * @return boolean
     */
    public static function save($profile, $label, $component_id, $block, $uid)
    {
        try {

            db_insert('flat_cmdi_templates')
            ->fields([
                'profile'      => $profile,
                'label'        => $label,
                'component_id' => $component_id,
                'block'        => $block,
                'uid'          => $uid,
            ])
            ->execute();

            return true;

        } catch (Exception $e) {

            static::error($e);
            return false;
        }
    }

    /**
     * db error was found, send drupal message to show what
     * went wrong
     *
     * @param Exception $e
     */
    public static function error(Exception $e)
    {
        if ($e->errorInfo[0] == '42P01') {
            drupal_set_message(t('Flat Cmdi Templates table not found. Try running <a href="@update_url">update.php</a>.', ['@update_url' => url('update.php')]), 'error');
        } else {
            drupal_set_message($e->getMessage(), 'error');
        }
    }
}