function validate() {
    var pass = document.getElementById("newpassword").value;
    var cpass = document.getElementById("cpassword").value;
    if (pass == cpass) {
        return true;
    } else {
        alert("رمز عبور و تکرار آن یکسان نیستند.");
        return false;
    }
}

