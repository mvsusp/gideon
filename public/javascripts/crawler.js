$(function() {
	$.getJSON('next_page.json', function(data) {
		result = reduce(data.url);
	});
});

reduce = function(url) {
	$.getJSON(url+'?jsoncallback=?', function(data) {
    result = word_count(data)
		$.post('page', result, function(data) {
			alert(data);
		});
	});
}

word_count = function(data) {
		var sum = 0;
		var docs = document.body.innerHTML.split(/\\n/);
    $.each(docs, function(key, value){
      sum++;
        });
    return sum 
}
