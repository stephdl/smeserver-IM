<?php echo $pref;?>("messenger.account.account1.alias", "<?php echo $user[0]['cn'][0]; ?>");
<?php echo $pref;?>("messenger.account.account1.autoLogin", true);
<?php echo $pref;?>("messenger.account.account1.name", "<?php echo $uid; ?>@<?php echo DOMAIN; ?>");
<?php echo $pref;?>("messenger.account.account1.options.server", "<?php echo HOSTNAME; ?>.<?php echo DOMAIN; ?>");
<?php echo $pref;?>("messenger.account.account1.prpl", "prpl-jabber");
<?php echo $pref;?>("messenger.account.account1.options.connection_security", "require_tls");
<?php echo $pref;?>("messenger.accounts", "account1");
