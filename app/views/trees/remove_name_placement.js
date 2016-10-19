
var json_result = <%=raw(@response)%>;

if(json_result.success) {
    $('#instance-classification-tab').click();
}
else {
    var block = $("#remove_name_error_block");
    block.empty();
    block.append("<div class='text-danger'><b><u>Could not remove name</u></b></div>");

    for(var i in json_result.msg) {
        block.append("<div class='text-"+json_result.msg[i].status+"'><b>"+json_result.msg[i].msg+"</b> "+json_result.msg[i].body+"</div>");

    }
}
