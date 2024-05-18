<?php

/* Prevent XSS input */
$_GET   = filter_input_array(INPUT_GET, FILTER_SANITIZE_STRING);
$_POST  = filter_input_array(INPUT_POST, FILTER_SANITIZE_STRING);

session_start();

require_once 'scripts/common.php';
$user = get_user();
$home = get_home();
$config = get_config();
set_timezone();

if(is_authenticated() && (!isset($_SESSION['behind']) || !isset($_SESSION['behind_time']) || time() > $_SESSION['behind_time'] + 86400)) {
  shell_exec("sudo -u".$user." git -C ".$home."/BirdNET-Pi fetch > /dev/null 2>/dev/null &");
  $str = trim(shell_exec("sudo -u".$user." git -C ".$home."/BirdNET-Pi status"));
  if (preg_match("/behind '.*?' by (\d+) commit(s?)\b/", $str, $matches)) {
    $num_commits_behind = $matches[1];
  }
  if (preg_match('/\b(\d+)\b and \b(\d+)\b different commits each/', $str, $matches)) {
    $num1 = (int) $matches[1];
    $num2 = (int) $matches[2];
    $num_commits_behind = $num1 + $num2;
  }
  if (stripos($str, "Your branch is up to date") !== false) {
    $num_commits_behind = '0';
  }
  $_SESSION['behind'] = $num_commits_behind;
  $_SESSION['behind_time'] = time();
}
if(isset($_SESSION['behind'])&&intval($_SESSION['behind']) >= 99) {?>
  <style>
  .updatenumber { 
    width:30px !important;
  }
  </style>
<?php }
if ($config["LATITUDE"] == "0.000" && $config["LONGITUDE"] == "0.000") {
  echo "<center style='color:red'><b>WARNING: Your latitude and longitude are not set properly. Please do so now in Tools -> Settings.</center></b>";
}
elseif ($config["LATITUDE"] == "0.000") {
  echo "<center style='color:red'><b>WARNING: Your latitude is not set properly. Please do so now in Tools -> Settings.</center></b>";
}
elseif ($config["LONGITUDE"] == "0.000") {
  echo "<center style='color:red'><b>WARNING: Your longitude is not set properly. Please do so now in Tools -> Settings.</center></b>";
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>BirdNET-Pi DB</title>
  <link rel="stylesheet" href="style.css?v=<?php echo date ('n.d.y', filemtime('style.css')); ?>">
</head>
<body>
<form action="views.php" method="GET" id="views">
<div class="topnav" id="myTopnav">
  <button type="submit" name="view" value="Overview" form="views">Overview</button>
  <button type="submit" name="view" value="Todays Detections" form="views">Today's Detections</button>
  <button type="submit" name="view" value="Spectrogram" form="views">Spectrogram</button>
  <button type="submit" name="view" value="Species Stats" form="views">Best Recordings</button>
  <button type="submit" name="view" value="Streamlit" form="views">Species Stats</button>
  <button type="submit" name="view" value="Daily Charts" form="views">Daily Charts</button>
  <button type="submit" name="view" value="Recordings" form="views">Recordings</button>
  <button type="submit" name="view" value="View Log" form="views">View Log</button>
  <button type="submit" name="view" value="Tools" form="views">Tools<?php if(isset($_SESSION['behind']) && intval($_SESSION['behind']) >= 50 && ($config['SILENCE_UPDATE_INDICATOR'] != 1)){ $updatediv = ' <div class="updatenumber">'.$_SESSION["behind"].'</div>'; } else { $updatediv = ""; } echo $updatediv; ?></button>
  <button type="button" href="javascript:void(0);" class="icon" onclick="myFunction()"><img src="images/menu.png"></button>
</div>
</form>

<script>
window.onload = function() {
  var elements = document.querySelectorAll("button[name=view]");

  var setViewsOpacity = function() {
      document.getElementsByClassName("views")[0].style.opacity = "0.5";
  };

  for (var i = 0; i < elements.length; i++) {
      elements[i].addEventListener('click', setViewsOpacity, false);
  }
};
var topbuttons = document.querySelectorAll("button[form='views']");
if(window.location.search.substr(1) != '') {
  for (var i = 0; i < topbuttons.length; i++) {
    if(topbuttons[i].value == decodeURIComponent(window.location.search.substr(1)).replace(/\+/g,' ').split('=').pop()) {
      topbuttons[i].classList.add("button-hover");
    }
  }
} else {
  topbuttons[0].classList.add("button-hover");
}
function copyOutput(elem) {
  elem.innerHTML = 'Copied!';
  const copyText = document.getElementsByTagName("pre")[0].textContent;
  const textArea = document.createElement('textarea');
  textArea.style.position = 'absolute';
  textArea.style.left = '-100%';
  textArea.textContent = copyText;
  document.body.append(textArea);
  textArea.select();
  document.execCommand("copy");
}
</script>

<div class="views">
<?php
if(isset($_GET['view'])){
  if($_GET['view'] == "System Info"){echo "<iframe src='phpsysinfo/index.php'></iframe>";}
  if($_GET['view'] == "System Controls"){
    ensure_authenticated();
    include('scripts/system_controls.php');
  }
  if($_GET['view'] == "Services"){
    ensure_authenticated();
    include('scripts/service_controls.php');
  }
  if($_GET['view'] == "Spectrogram"){include('spectrogram.php');}
  if($_GET['view'] == "View Log"){echo "<body style=\"scroll:no;overflow-x:hidden;\"><iframe style=\"width:calc( 100% + 1em);\" src=\"/log\"></iframe></body>";}
  if($_GET['view'] == "Overview"){include('overview.php');}
  if($_GET['view'] == "Todays Detections"){include('todays_detections.php');}
  if($_GET['view'] == "Kiosk"){$kiosk = true;include('todays_detections.php');}
  if($_GET['view'] == "Species Stats"){include('stats.php');}
  if($_GET['view'] == "Weekly Report"){include('weekly_report.php');}
  if($_GET['view'] == "Streamlit"){echo "<iframe src=\"/stats\"></iframe>";}
  if($_GET['view'] == "Daily Charts"){include('history.php');}
  if($_GET['view'] == "Tools"){
    ensure_authenticated();
    $url = $_SERVER['SERVER_NAME']."/scripts/adminer.php";
    echo "<div class=\"centered\">
      <form action=\"views.php\" method=\"GET\" id=\"views\">
      <button type=\"submit\" name=\"view\" value=\"Settings\" form=\"views\">Settings</button>
      <button type=\"submit\" name=\"view\" value=\"System Info\" form=\"views\">System Info</button>
      <button type=\"submit\" name=\"view\" value=\"System Controls\" form=\"views\">System Controls".$updatediv."</button>
      <button type=\"submit\" name=\"view\" value=\"Services\" form=\"views\">Services</button>
      <button type=\"submit\" name=\"view\" value=\"File\" form=\"views\">File Manager</button>
      <a href=\"scripts/adminer.php\" target=\"_blank\"><button type=\"submit\" form=\"\">Database Maintenance</button></a>
      <button type=\"submit\" name=\"view\" value=\"Webterm\" form=\"views\">Web Terminal</button>
      <button type=\"submit\" name=\"view\" value=\"Included\" form=\"views\">Custom Species List</button>
      <button type=\"submit\" name=\"view\" value=\"Excluded\" form=\"views\">Excluded Species List</button>
      <button type=\"submit\" name=\"view\" value=\"Converted\" form=\"views\">Converted Species List</button>
      </form>
      </div>";
  }
  if($_GET['view'] == "Recordings"){include('play.php');}
  if($_GET['view'] == "Settings"){include('scripts/config.php');} 
  if($_GET['view'] == "Advanced"){include('scripts/advanced.php');}
  if($_GET['view'] == "Included"){
    ensure_authenticated();
    if(isset($_GET['species']) && isset($_GET['add'])){
      $file = './scripts/include_species_list.txt';
      $str = file_get_contents("$file");
      $str = preg_replace("/(^[\r\n]*|[\r\n]+)[\s\t]*[\r\n]+/", "\n", $str);
      file_put_contents("$file", "$str");
      if(isset($_GET['species'])){
        foreach ($_GET['species'] as $selectedOption)
          file_put_contents("./scripts/include_species_list.txt", htmlspecialchars_decode($selectedOption, ENT_QUOTES)."\n", FILE_APPEND);
      }
    } elseif(isset($_GET['species']) && isset($_GET['del'])){
      $file = './scripts/include_species_list.txt';
      $str = file_get_contents("$file");
      $str = preg_replace('/^\h*\v+/m', '', $str);
      file_put_contents("$file", "$str");
      foreach($_GET['species'] as $selectedOption) {
        $content = file_get_contents("../BirdNET-Pi/include_species_list.txt");
        $newcontent = str_replace($selectedOption, "", "$content");
        $newcontent = str_replace(htmlspecialchars_decode($selectedOption, ENT_QUOTES), "", "$newcontent");
        file_put_contents("./scripts/include_species_list.txt", "$newcontent");
      }
      $file = './scripts/include_species_list.txt';
      $str = file_get_contents("$file");
      $str = preg_replace('/^\h*\v+/m', '', $str);
      file_put_contents("$file", "$str");
    }
    include('./scripts/include_list.php');
  }
  if($_GET['view'] == "Excluded"){
    ensure_authenticated();
    if(isset($_GET['species']) && isset($_GET['add'])){
      $file = './scripts/exclude_species_list.txt';
      $str = file_get_contents("$file");
      $str = preg_replace("/(^[\r\n]*|[\r\n]+)[\s\t]*[\r\n]+/", "\n", $str);
      file_put_contents("$file", "$str");
      foreach ($_GET['species'] as $selectedOption)
        file_put_contents("./scripts/exclude_species_list.txt", htmlspecialchars_decode($selectedOption, ENT_QUOTES)."\n", FILE_APPEND);
    } elseif (isset($_GET['species']) && isset($_GET['del'])){
      $file = './scripts/exclude_species_list.txt';
      $str = file_get_contents("$file");
      $str = preg_replace('/^\h*\v+/m', '', $str);
      file_put_contents("$file", "$str");
      foreach($_GET['species'] as $selectedOption) {
        $content = file_get_contents("./scripts/exclude_species_list.txt");
        $newcontent = str_replace($selectedOption, "", "$content");
        $newcontent = str_replace(htmlspecialchars_decode($selectedOption, ENT_QUOTES), "", "$content");
        file_put_contents("./scripts/exclude_species_list.txt", "$newcontent");
      }
      $file = './scripts/exclude_species_list.txt';
      $str = file_get_contents("$file");
      $str = preg_replace('/^\h*\v+/m', '', $str);
      file_put_contents("$file", "$str");
    }
    include('./scripts/exclude_list.php');
  }
  if($_GET['view'] == "Converted"){
    ensure_authenticated();
	if(isset($_GET['species']) && isset($_GET['add'])){
	  $file = './scripts/convert_species_list.txt';
	  $str = file_get_contents("$file");
	  $str = preg_replace("/(^[\r\n]*|[\r\n]+)[\s\t]*[\r\n]+/", "\n", $str);
	  file_put_contents("$file", "$str");
	  // Write $_GET['species'] to the file
	  file_put_contents("./scripts/convert_species_list.txt", htmlspecialchars_decode($_GET['species'], ENT_QUOTES)."\n", FILE_APPEND);
      } elseif (isset($_GET['species']) && isset($_GET['del'])){
      $file = './scripts/convert_species_list.txt';
      $str = file_get_contents("$file");
      $str = preg_replace('/^\h*\v+/m', '', $str);
      file_put_contents("$file", "$str");
      foreach($_GET['species'] as $selectedOption) {
        $content = file_get_contents("./scripts/convert_species_list.txt");
        $newcontent = str_replace($selectedOption, "", "$content");
        $newcontent = str_replace(htmlspecialchars_decode($selectedOption, ENT_QUOTES), "", "$content");
        file_put_contents("./scripts/convert_species_list.txt", "$newcontent");
      }
      $file = './scripts/convert_species_list.txt';
      $str = file_get_contents("$file");
      $str = preg_replace('/^\h*\v+/m', '', $str);
      file_put_contents("$file", "$str");
    }
    include('./scripts/convert_list.php');
  }
  if($_GET['view'] == "File"){
    echo "<iframe src='scripts/filemanager/filemanager.php'></iframe>";
  }
  if($_GET['view'] == "Webterm"){
    ensure_authenticated('You cannot access the web terminal');
    echo "<iframe src='/terminal'></iframe>";
  }
} elseif(isset($_GET['submit'])) {
  ensure_authenticated();
  $allowedCommands = array('sudo systemctl stop livestream.service && sudo systemctl stop icecast2.service',
                     'sudo systemctl restart livestream.service && sudo systemctl restart icecast2.service',
                     'sudo systemctl disable --now livestream.service && sudo systemctl disable icecast2 && sudo systemctl stop icecast2.service',
                     'sudo systemctl enable icecast2 && sudo systemctl start icecast2.service && sudo systemctl enable --now livestream.service',
                     'sudo systemctl stop web_terminal.service',
                     'sudo systemctl restart web_terminal.service',
                     'sudo systemctl disable --now web_terminal.service',
                     'sudo systemctl enable --now web_terminal.service',
                     'sudo systemctl stop birdnet_log.service',
                     'sudo systemctl restart birdnet_log.service',
                     'sudo systemctl disable --now birdnet_log.service',
                     'sudo systemctl enable --now birdnet_log.service',
                     'sudo systemctl stop birdnet_analysis.service',
                     'sudo systemctl restart birdnet_analysis.service',
                     'sudo systemctl disable --now birdnet_analysis.service',
                     'sudo systemctl enable --now birdnet_analysis.service',
                     'sudo systemctl stop birdnet_stats.service',
                     'sudo systemctl restart birdnet_stats.service',
                     'sudo systemctl disable --now birdnet_stats.service',
                     'sudo systemctl enable --now birdnet_stats.service',
                     'sudo systemctl stop birdnet_recording.service',
                     'sudo systemctl restart birdnet_recording.service',
                     'sudo systemctl disable --now birdnet_recording.service',
                     'sudo systemctl enable --now birdnet_recording.service',
                     'sudo systemctl stop chart_viewer.service',
                     'sudo systemctl restart chart_viewer.service',
                     'sudo systemctl disable --now chart_viewer.service',
                     'sudo systemctl enable --now chart_viewer.service',
                     'sudo systemctl stop spectrogram_viewer.service',
                     'sudo systemctl restart spectrogram_viewer.service',
                     'sudo systemctl disable --now spectrogram_viewer.service',
                     'sudo systemctl enable --now spectrogram_viewer.service',
                     'sudo systemctl enable '.get_service_mount_name().' && sudo reboot',
                     'sudo systemctl disable '.get_service_mount_name().' && sudo reboot',
                     'stop_core_services.sh',
                     'restart_services.sh',
                     'sudo reboot',
                     'update_birdnet.sh',
                     'sudo shutdown now',
                     'sudo clear_all_data.sh');
    $command = $_GET['submit'];
    if(in_array($command,$allowedCommands)){
      if(isset($command)){
        $initcommand = $command;
		  if (strpos($command, "systemctl") !== false) {
			  //If there more than one command to execute, processes then separately
			  //currently only livestream service uses multiple commands to interact with the required services
			  if (strpos($command, " && ") !== false) {
				  $separate_commands = explode("&&", trim($command));
				  $new_multiservice_status_command = "";
				  foreach ($separate_commands as $indiv_service_command) {
					  //explode the string by " " space so we can get each individual component of the command
					  //and eventually the service name at the end
					  $separate_command_tmp = explode(" ", trim($indiv_service_command));
					  //get the service names
					  $new_multiservice_status_command .= " " . trim(end($separate_command_tmp));
				  }

				  $service_names = $new_multiservice_status_command;
			  } else {
                  //only one service needs restarting so we only need to query the status of one service
				  $tmp = explode(" ", trim($command));
				  $service_names = end($tmp);
			  }

          $command .= " & sleep 3;sudo systemctl status " . $service_names;
        }
        if($initcommand == "update_birdnet.sh") {
          session_unset();
        }
        $results = shell_exec("$command 2>&1");
        $results = str_replace("FAILURE", "<span style='color:red'>FAILURE</span>", $results);
        $results = str_replace("failed", "<span style='color:red'>failed</span>",$results);
        $results = str_replace("active (running)", "<span style='color:green'><b>active (running)</b></span>",$results);
        $results = str_replace("Your branch is up to date", "<span style='color:limegreen'><b>Your branch is up to date</b></span>",$results);

        $results = str_replace("(+)", "(<span style='color:lime;font-weight:bold'>+</span>)",$results);
        $results = str_replace("(-)", "(<span style='color:red;font-weight:bold'>-</span>)",$results);

        // split the input string into lines
        $lines = explode("\n", $results);

        // iterate over each line
        foreach ($lines as &$line) {
            // check if the line matches the pattern
            if (preg_match('/^(.+?)\s*\|\s*(\d+)\s*([\+\- ]+)(\d+)?$/', $line, $matches)) {
                // extract the filename, count, and indicator letters
                $filename = $matches[1];
                $count = $matches[2];
                $diff = $matches[3];
                $delta = $matches[4] ?? '';
                // determine the indicator letters
                $diff_array = str_split($diff);
                $indicators = array_map(function ($d) use ($delta) {
                    if ($d === '+') {
                        return "<span style='color:lime;'><b>+</b></span>";
                    } elseif ($d === '-') {
                        return "<span style='color:red;'><b>-</b></span>";
                    } elseif ($d === ' ') {
                        if ($delta !== '') {
                            return 'A';
                        } else {
                            return ' ';
                        }
                    }
                }, $diff_array);
                // modify the line with the new indicator letters
                $line = sprintf('%-35s|%3d %s%s', $filename, $count, implode('', $indicators), $delta);
            }
        }

        // rejoin the modified lines into a string
        $output = implode("\n", $lines);
        $results = $output;

        // remove script tags (xss)
        $results = preg_replace('#<script(.*?)>(.*?)</script>#is', '', $results);
        if(strlen($results) == 0) {
          $results = "This command has no output.";
        }
        echo "<table style='min-width:70%;'><tr class='relative'><th>Output of command:`".$initcommand."`<button class='copyimage' style='right:40px' onclick='copyOutput(this);'>Copy</button></th></tr><tr><td style='padding-left: 0px;padding-right: 0px;padding-bottom: 0px;padding-top: 0px;'><pre class='bash' style='text-align:left;margin:0px'>$results</pre></td></tr></table>"; 
      }
    }
  ob_end_flush();
} else {include('overview.php');}
?>
<script>
function myFunction() {
  var x = document.getElementById("myTopnav");
  if (x.className === "topnav") {
    x.className += " responsive";
  } else {
    x.className = "topnav";
  }
}
function setLiveStreamVolume(vol) {
  var audioelement =  window.parent.document.getElementsByTagName("audio")[0];
  if (typeof(audioelement) != 'undefined' && audioelement != null)
  {
    audioelement.volume = vol
  }
}
window.onbeforeunload = function(event) {
  // if the user is playing a video and then navigates away mid-play, the live stream audio should be unmuted again
  var audioelement =  window.parent.document.getElementsByTagName("audio")[0];
  if (typeof(audioelement) != 'undefined' && audioelement != null)
  {
    audioelement.volume = 1
  }
}

function getTheDate(increment) {
  var theDate = "<?php if (isset($theDate)) echo $theDate;?>";

  d = new Date(theDate);
  d.setDate(d.getDate(theDate) + increment);
  yyyy = d.getFullYear();
  mm = d.getMonth() + 1; if (mm < 10) mm = "0" + mm;
  dd = d.getDate(); if (dd < 10) dd = "0" + dd;

  document.getElementById("SwipeSpinner").hidden = false;
  
  window.location = "/views.php?date="+yyyy+"-"+mm+"-"+dd+"&view=Daily+Charts";
}

function installKeyAndSwipeEventHandler() {
  for (var i = 0; i < topbuttons.length; i++) {
    if (topbuttons[i].textContent == "Daily Charts" && 
        topbuttons[i].className == "button-hover") {

      document.onkeydown = function(event) {
        switch (event.keyCode) {
          case 37: //Left key
            getTheDate(-1);
            break;
          case 39: //Right key
            getTheDate(+1);
            break;
        }
      };

      // https://stackoverflow.com/questions/2264072/detect-a-finger-swipe-through-javascript-on-the-iphone-and-android
      let touchstartX = 0;
      let diffX = 0;
      let touchstartY = 0;
      let diffY = 0;
      let startTime = 0;
      let diffTime = 0;
    
      function checkDirection() {
        if (Math.abs(diffX) > Math.abs(diffY) && diffTime < 500) {
          if (diffX > 20) getTheDate(+1);
          if (diffX < -20) getTheDate(-1);
        }
      }

      document.addEventListener('touchstart', e => {
        touchstartX = e.changedTouches[0].screenX;
        touchstartY = e.changedTouches[0].screenY;
        startTime = Date.now();
      });

      document.addEventListener('touchend', e => {
        diffX = touchstartX - e.changedTouches[0].screenX;
        diffY = touchstartY - e.changedTouches[0].screenY;
        diffTime = Date.now() - startTime;
        checkDirection();
      });
    }
  }
}

installKeyAndSwipeEventHandler();
</script>
</div>
</body>
