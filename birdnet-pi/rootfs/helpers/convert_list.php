<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
</style>

<p><strong>This tool will allow to convert on-the-fly species to compensate for model errors. It SHOULD NOT BE USED except if you know what you are doing, instead the model errors should be reported to the owner. However, it is still convenient for systematic biases that are confirmed through careful listening of samples, while waiting for the models to be updated.</strong></p>

<div class="customlabels column1">
<form action="" method="GET" id="add">
  <input type="hidden" id="species" name="species">
  <h3>Specie to convert from :</h3>
  <!-- Input box to filter options in the first table -->
  <input type="text" id="species1Search" onkeyup="filterOptions('species1')" placeholder="Search for species...">
  <select name="species1" id="species1" size="25">
  <?php
    error_reporting(E_ALL);
    ini_set('display_errors',1);

    $filename = './scripts/labels.txt';
    $eachline = file($filename, FILE_IGNORE_NEW_LINES);

    foreach($eachline as $lines){echo
  "<option value=\"".$lines."\">$lines</option>";}
  ?>
  </select>
  <br><br> <!-- Added a space between the two tables -->
  <h3>Specie to convert to :</h3>
  <!-- Input box to filter options in the second table -->
  <input type="text" id="species2Search" onkeyup="filterOptions('species2')" placeholder="Search for species...">
  <select name="species2" id="species2" size="25">
  <?php
    foreach($eachline as $lines){echo
  "<option value=\"".$lines."\">$lines</option>";}
  ?>
  </select>
  <input type="hidden" name="add" value="add">
</form>
<div class="customlabels smaller">
  <button type="submit" name="view" value="Converted" form="add">>>ADD>></button>
</div>
</div>

<div class="customlabels column2">
  <table><td>
  <button type="submit" name="view" value="Converted" form="add">>>ADD>></button>
  <br><br>
  <button type="submit" name="view" value="Converted" form="del">REMOVE</button>
  </td></table>
</div>

<div class="customlabels column3" style="margin-top: 0;"> <!-- Removed the blank space above the table -->
<form action="" method="GET" id="del">
  <h3>Converted Species List</h3>
  <select name="species[]" id="value2" multiple size="25">
<?php
  $filename = './scripts/convert_species_list.txt'; // Changed the file path
  $eachline = file($filename, FILE_IGNORE_NEW_LINES);
  foreach($eachline as $lines){
    echo
  "<option value=\"".$lines."\">$lines</option>";
}?>
  </select>
  <input type="hidden" name="del" value="del">
</form>
<div class="customlabels smaller">
  <button type="submit" name="view" value="Converted" form="del">REMOVE</button>
</div>
</div>

<input type="hidden" id="hiddenSpecies" name="hiddenSpecies">

<script>
    document.getElementById("add").addEventListener("submit", function(event) {
      var speciesSelect1 = document.getElementById("species1");
      var speciesSelect2 = document.getElementById("species2");
      if (speciesSelect1.selectedIndex < 0 || speciesSelect2.selectedIndex < 0) {
        alert("Please select a species from both lists.");
        document.querySelector('.views').style.opacity = 1;
        event.preventDefault();
      } else {
        var selectedSpecies1 = speciesSelect1.options[speciesSelect1.selectedIndex].value;
        var selectedSpecies2 = speciesSelect2.options[speciesSelect2.selectedIndex].value;
        document.getElementById("species").value = selectedSpecies1 + ";" + selectedSpecies2;
      }
    });

    // Store the original list of options in a variable
    var originalOptions = {};
    
    // Function to filter options in a select element
    function filterOptions(id) {
      var input = document.getElementById(id + "Search");
      var filter = input.value.toUpperCase();
      var select = document.getElementById(id);
      var options = select.getElementsByTagName("option");
    
      // If the original list of options for this select element hasn't been stored yet, store it
      if (!originalOptions[id]) {
        originalOptions[id] = Array.from(options).map(option => option.value);
      }
    
      // Clear the select element
      while (select.firstChild) {
        select.removeChild(select.firstChild);
      }
    
      // Populate the select element with the filtered labels
      originalOptions[id].forEach(label => {
        if (label.toUpperCase().indexOf(filter) > -1) {
          let option = document.createElement('option');
          option.value = label;
          option.text = label;
          select.appendChild(option);
        }
      });
    }
</script>
