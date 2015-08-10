// ====================================== //
//  Document Ready                        //
// ====================================== //
$(document).ready(function() {
	debug('Loading navigation event handlers');

	
	$('ul.nav-tabs li a').on('keydown',function(event) {
	  debug('ul.nav-tabs li a keydown event: ' + event.keyCode + '; shifted: ' + event.shiftKey.toString());
	  var retval = false;
		switch(event.keyCode)
		{
	  case 9:
	    if (event.shiftKey) {
		    debug('backtab');
		    if ( $(this).attr('data-prev-tab') ) {
			    debug('backtab to ' + $(this).attr('data-prev-tab'));
			    $($(this).attr('data-prev-tab')).focus();
			    retval = false;
		    } else {
			    debug('backtab normally');
			    retval = true;
		    }
	    } else {
		    debug('tab');
		    if ( $(this).attr('data-next-tab') ) {
			    $($(this).attr('data-next-tab')).focus();
			    retval = false;
		    } else {
		      debug('no data-next-tab attribute so returning true');
			    retval = true;
		    }
	    }
	    break;
		case 37:  // arrow left
	    if ( $(this).attr('data-prev-tab') ) {
		    $($(this).attr('data-prev-tab')).focus();
	    } else {
		    $(this).closest('li').prev().children('a').focus();
	    }
	    retval = false;
		  break;
		case 38:  // arrow up
		  $('.view-edit-toggle').focus();
		  debug('arrow up');
			retval = false;
		  break;
		case 39:  // arrow right	
			if ( $(this).attr('data-arrow-right') ) {
		    $($(this).attr('data-arrow-right')).focus();
	    } else {
		    $(this).closest('li').next().children('a').focus();
	    }
			retval = false;
		  break;
		default:
		  retval = true;
		}
		return(retval);
  });


	$('select.bypasses-tabindex').on('keydown',function(event) {
	  debug('select.bypasses-tabindex keydown event: ' + event.keyCode);
	  var retval = false;
		switch(event.keyCode)
		{
	  case 9:    // tab
	    if (event.shiftKey) {
		    debug('backtab');
		    retval = true;
	    } else {
		    debug('tab');
		    if ( $(this).attr('data-next-tab') ) {
			    $($(this).attr('data-next-tab')).focus();
			    retval = false;
		    } else {
			    retval = true;
		    }
	    }
	    break;

		default:
		  retval = true;
		}
		return(retval);
  });

	debug('End of loading navigation event handlers');
});  // end of document ready
