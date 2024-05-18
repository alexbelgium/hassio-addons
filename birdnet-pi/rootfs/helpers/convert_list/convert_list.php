<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  /* Add your custom styles here */
</style>

<p><strong>This tool will allow to convert on-the-fly species to compensate for model errors. It SHOULD NOT BE USED except if you know what you are doing, instead the model errors should be reported to the owner. However, it is still convenient for systematic biases that are confirmed through careful listening of samples, while waiting for the models to be updated.</strong></p>

<div class="customlabels column1">
  <form action="" method="GET" id="add">
    <input type="hidden" id="species" name="species">
    <h3>Specie to convert from:</h3>
    <input type="text" id="species1Search" placeholder="Search for species...">
    <select name="species1" id="species1" size="25"></select>
    <br><br>
    <h3>Specie to convert to:</h3>
    <input type="text" id="species2Search" placeholder="Search for species...">
    <select name="species2" id="species2" size="25"></select>
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
  // Assuming labels are defined in PHP and passed to JavaScript
  var labels1 = <?php echo json_encode($eachline); ?>;
  var labels2 = <?php echo json_encode($eachline); ?>;

  document.getElementById('species1Search').addEventListener('keyup', function() {
    filterOptions('species1', labels1);
  });

  document.getElementById('species2Search').addEventListener('keyup', function() {
    filterOptions('species2', labels2);
  });
  
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

  // Function to filter options in a select element
  function filterOptions(id, labels) {
    var input = document.getElementById(id + 'Search');
    var filter = input.value.toUpperCase();
    var select = document.getElementById(id);
    // Clear the current options
    while (select.firstChild) {
      select.removeChild(select.firstChild);
    }
    // Populate the select with options that match the filter
    labels.forEach(function(label) {
      if (label.toUpperCase().indexOf(filter) > -1) {
        var option = document.createElement('option');
        option.value = label;
        option.text = label;
        select.appendChild(option);
      }
    });
  }
</script>
