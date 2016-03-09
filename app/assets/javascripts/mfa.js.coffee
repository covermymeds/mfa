# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  $("#verify_code").on("ajax:success", (e, data, status, xhr) ->
      alert data
  ).on "ajax:error", (e, data, status, xhr) ->
     $("#alerts").append ->
       '<div class="alert alert-error alert-dismissable">'+
       '<button type="button" class="close" ' + 
       'data-dismiss="alert" aria-hidden="true">' + 
       '&times;' + 
       '</button>' + 
       'Unable to verify the MFA token.  Please double check it and try again' + 
       '</div>'
