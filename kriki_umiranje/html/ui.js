  function startTimer() {
    var presentTime = document.getElementById('timer').innerHTML;
    var timeArray = presentTime.split(/[:]+/);
    var m = timeArray[0];
    var s = checkSecond((timeArray[1] - 1));
    if(s==59){m=m-1}
    if(m<0){
      return
    }
    
    document.getElementById('timer').innerHTML =
      m + ":" + s;
    
  }
  
  function checkSecond(sec) {
    if (sec < 10 && sec >= 0) {sec = "0" + sec};
    if (sec < 0) {sec = "59"};
    return sec;
  }

$(document).ready(function(){
	
    window.addEventListener('message', function( event ) {     
      if (event.data.action == 'open') {
		$('body').css('display', 'block');
		document.getElementById('timer').innerHTML = 19 + ":" + 59;
		startTimer();
	  } else if (event.data.action == 'timer') {
		startTimer()
      } else {
        $('body').css('display', 'none');
      }
    });
});
