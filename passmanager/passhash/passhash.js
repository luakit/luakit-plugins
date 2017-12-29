var browser = new Object();
browser.version = parseInt(navigator.appVersion);
browser.isNetscape = false;
browser.isMicrosoft = false;
if (navigator.appName.indexOf("Netscape") != -1)
    browser.isNetscape = true;
else if (navigator.appName.indexOf("Microsoft") != -1)
    browser.isMicrosoft = true;

var siteTagLast = '';
var masterKeyLast = '';

function passhash_onLoad()
{
    if (browser.isMicrosoft)
    {
        document.getElementById('reveal').disabled = true;
        document.getElementById('reveal-text').disabled = true;
    }
    document.getElementById('site-tag').focus();
    setTimeout('passhash_checkChange()',1000);
}

function passhash_validate(form)
{
    var siteTag   = document.getElementById('site-tag');
    var masterKey = document.getElementById('master-key');
    if (!siteTag.value)
    {
        siteTag.focus();
        return false;
    }
    if (!masterKey.value)
    {
        masterKey.focus();
        return false;
    }
    return true;
}

function passhash_update()
{
    var siteTag   = document.getElementById('site-tag');
    var masterKey = document.getElementById('master-key');
    var hashWord  = document.getElementById('hash-word');
    //var hashapass = b64_hmac_sha1(masterKey.value, siteTag.value).substr(0,8);
    var hashWordSize       = 8;
    var requireDigit       = document.getElementById("digit").checked;
    var requirePunctuation = document.getElementById("punctuation").checked;
    var requireMixedCase   = document.getElementById("mixedCase").checked;
    var restrictSpecial    = document.getElementById("noSpecial").checked;
    var restrictDigits     = document.getElementById("digitsOnly").checked;
    hashWordSize = document.getElementById("passhash-password-size" ).value;
    hashWord.value = PassHashCommon.generateHashWord(
        siteTag.value,
        masterKey.value,
        hashWordSize,
        requireDigit,
        requirePunctuation,
        requireMixedCase,
        restrictSpecial,
        restrictDigits);
    masterKey.focus();
    var hashOptions  = document.getElementById('passhash-options');
    if (hashOptions) {
        hashOptions.value=siteTag+'/'+
            (requireDigit?'d':'')+
            (requirePunctuation?'p':'')+
            (requireMixedCase?'m':'')+
            (restrictSpecial?'r':'')+
            (restrictDigits?'g':'')+
            hashWordSize
    }
    siteTagLast = siteTag.value;
    masterKeyLast = masterKey.value;
}

function passhash_showHideSection(id, sectionName, fld) {
    var div = document.getElementById(id);
    if (div.style.display == 'none') {
        div.style.display = 'block';
        fld.innerHTML="&darr; "+sectionName;
    } else {
        div.style.display = 'none';
        fld.innerHTML="&rarr; "+sectionName;
    }
}

function passhash_onUpdateMaster() {
    var masterKey = document.getElementById('master-key');
    passhash_update();
    masterKey.focus();
    masterKey.selectionStart = masterKey.value.length;
}

function passhash_checkChange()
{
    var siteTag   = document.getElementById('site-tag');
    var masterKey = document.getElementById('master-key');
    var hashWord  = document.getElementById('hash-word');
    if (siteTag.value != siteTagLast || masterKey.value != masterKeyLast)
    {
        hashWord.value = '';
        siteTagLast = siteTag.value;
        masterKeyLast = masterKey.value;
    }
    setTimeout('passhash_checkChange()', 1000);
}

function passhash_onLeaveResultField(hashWord)
{
    var submit = document.getElementById('submit');
    submit.value = 'OK';
//    hashWord.value = '';
    document.getElementById('prompt').innerHTML = '';
}

function passhash_onReveal(fld)
{
    var masterKey = document.getElementById('master-key');
    var hashWord = document.getElementById('hash-word');
    var revealButton = document.getElementById('reveal');
    try
    {
        if (masterKey.getAttribute("type") == "password") {
            masterKey.setAttribute("type", "");
            hashWord.setAttribute("type", "");
            revealButton.innerHTML = "Hide";
        } else {
            masterKey.setAttribute("type", "password");
            hashWord.setAttribute("type", "password");
            revealButton.innerHTML = "Reveal";
        }
    } catch (ex) {}

    masterKey.focus();
}

function passhash_onNoSpecial(fld)
{
    document.getElementById('punctuation').disabled = fld.checked;
    passhash_update();
}

function passhash_onDigitsOnly(fld)
{
    document.getElementById('punctuation').disabled = fld.checked;
    document.getElementById("digit"      ).disabled = fld.checked;
    document.getElementById("punctuation").disabled = fld.checked;
    document.getElementById("mixedCase"  ).disabled = fld.checked;
    document.getElementById("noSpecial"  ).disabled = fld.checked;
    passhash_update();
}

function passhash_onBump()
{
    var siteTag = document.getElementById("site-tag");
    siteTag.value = PassHashCommon.bumpSiteTag(siteTag.value);
    passhash_update();
}

function onSelectSiteTag(fld)
{
    var siteTag = document.getElementById('site-tag');
    siteTag.value = fld[fld.selectedIndex].text;
    var options = fld[fld.selectedIndex].value;
    document.getElementById("digit"      ).checked  = (options.search(/d/i) >= 0);
    document.getElementById("punctuation").checked  = (options.search(/p/i) >= 0);
    document.getElementById("mixedCase"  ).checked  = (options.search(/m/i) >= 0);
    document.getElementById("noSpecial"  ).checked  = (options.search(/r/i) >= 0);
    document.getElementById("digitsOnly" ).checked  = (options.search(/g/i) >= 0);
    document.getElementById('punctuation').disabled = (options.search(/[rg]/i) >= 0);
    document.getElementById("digit"      ).disabled = (options.search(/g/i) >= 0);
    document.getElementById("punctuation").disabled = (options.search(/g/i) >= 0);
    document.getElementById("mixedCase"  ).disabled = (options.search(/g/i) >= 0);
    document.getElementById("noSpecial"  ).disabled = (options.search(/g/i) >= 0);
    var sizeMatch = options.match(/[0-9]+/);
    var hashWordSize = (sizeMatch != null && sizeMatch.length > 0
                                ? parseInt(sizeMatch[0])
                                : 16);
    document.getElementById("s6" ).checked = (hashWordSize == 6 );
    document.getElementById("s8" ).checked = (hashWordSize == 8 );
    document.getElementById("s10").checked = (hashWordSize == 10);
    document.getElementById("s12").checked = (hashWordSize == 12);
    document.getElementById("s14").checked = (hashWordSize == 14);
    document.getElementById("s16").checked = (hashWordSize == 16);
    document.getElementById("s18").checked = (hashWordSize == 18);
    document.getElementById("s20").checked = (hashWordSize == 20);
    document.getElementById("s22").checked = (hashWordSize == 22);
    document.getElementById("s24").checked = (hashWordSize == 24);
    document.getElementById("s26").checked = (hashWordSize == 26);
    if (passhash_validate())
        passhash_update();
}

function onLeaveSelectSiteTag(fld)
{
    // Remove the prompt
    document.getElementById('prompt').innerHTML = '';
}

/*
 * A JavaScript implementation of the Secure Hash Algorithm, SHA-1, as defined
 * in FIPS PUB 180-1
 * Version 2.1a Copyright Paul Johnston 2000 - 2002.
 * Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet
 * Distributed under the BSD License
 * See http://pajhome.org.uk/crypt/md5 for details.
 */

/*
 * Configurable variables. You may need to tweak these to be compatible with
 * the server-side, but the defaults work in most cases.
 */
var hexcase = 0;  /* hex output format. 0 - lowercase; 1 - uppercase        */
var b64pad  = ""; /* base-64 pad character. "=" for strict RFC compliance   */
var chrsz   = 8;  /* bits per input character. 8 - ASCII; 16 - Unicode      */

/*
 * These are the functions you'll usually want to call
 * They take string arguments and return either hex or base-64 encoded strings
 */
function hex_sha1(s){return binb2hex(core_sha1(str2binb(s),s.length * chrsz));}
function b64_sha1(s){return binb2b64(core_sha1(str2binb(s),s.length * chrsz));}
function str_sha1(s){return binb2str(core_sha1(str2binb(s),s.length * chrsz));}
function hex_hmac_sha1(key, data){ return binb2hex(core_hmac_sha1(key, data));}
function b64_hmac_sha1(key, data){ return binb2b64(core_hmac_sha1(key, data));}
function str_hmac_sha1(key, data){ return binb2str(core_hmac_sha1(key, data));}

/*
 * Perform a simple self-test to see if the VM is working
 */
function sha1_vm_test()
{
  return hex_sha1("abc") == "a9993e364706816aba3e25717850c26c9cd0d89d";
}

/*
 * Calculate the SHA-1 of an array of big-endian words, and a bit length
 */
function core_sha1(x, len)
{
  /* append padding */
  /* SC - Get rid of warning */
  var i = (len >> 5);
  if (x[i] == undefined)
      x[i]  = 0x80 << (24 - len % 32);
  else
      x[i] |= 0x80 << (24 - len % 32);
  /*x[len >> 5] |= 0x80 << (24 - len % 32);*/
  x[((len + 64 >> 9) << 4) + 15] = len;

  var w = Array(80);
  var a =  1732584193;
  var b = -271733879;
  var c = -1732584194;
  var d =  271733878;
  var e = -1009589776;

  for(var i = 0; i < x.length; i += 16)
  {
    var olda = a;
    var oldb = b;
    var oldc = c;
    var oldd = d;
    var olde = e;

    for(var j = 0; j < 80; j++)
    {
      if(j < 16) w[j] = x[i + j];
      else w[j] = rol(w[j-3] ^ w[j-8] ^ w[j-14] ^ w[j-16], 1);
      var t = safe_add(safe_add(rol(a, 5), sha1_ft(j, b, c, d)),
                       safe_add(safe_add(e, w[j]), sha1_kt(j)));
      e = d;
      d = c;
      c = rol(b, 30);
      b = a;
      a = t;
    }

    a = safe_add(a, olda);
    b = safe_add(b, oldb);
    c = safe_add(c, oldc);
    d = safe_add(d, oldd);
    e = safe_add(e, olde);
  }
  return Array(a, b, c, d, e);

}

/*
 * Perform the appropriate triplet combination function for the current
 * iteration
 */
function sha1_ft(t, b, c, d)
{
  if(t < 20) return (b & c) | ((~b) & d);
  if(t < 40) return b ^ c ^ d;
  if(t < 60) return (b & c) | (b & d) | (c & d);
  return b ^ c ^ d;
}

/*
 * Determine the appropriate additive constant for the current iteration
 */
function sha1_kt(t)
{
  return (t < 20) ?  1518500249 : (t < 40) ?  1859775393 :
         (t < 60) ? -1894007588 : -899497514;
}

/*
 * Calculate the HMAC-SHA1 of a key and some data
 */
function core_hmac_sha1(key, data)
{
  var bkey = str2binb(key);
  if(bkey.length > 16) bkey = core_sha1(bkey, key.length * chrsz);

  var ipad = Array(16), opad = Array(16);
  for(var i = 0; i < 16; i++)
  {
    /* SC - Get rid of warning */
    var k = (bkey[i] != undefined ? bkey[i] : 0);
    ipad[i] = k ^ 0x36363636;
    opad[i] = k ^ 0x5C5C5C5C;
/*  ipad[i] = bkey[i] ^ 0x36363636;
    opad[i] = bkey[i] ^ 0x5C5C5C5C;*/
  }

  var hash = core_sha1(ipad.concat(str2binb(data)), 512 + data.length * chrsz);
  return core_sha1(opad.concat(hash), 512 + 160);
}

/*
 * Add integers, wrapping at 2^32. This uses 16-bit operations internally
 * to work around bugs in some JS interpreters.
 */
function safe_add(x, y)
{
  var lsw = (x & 0xFFFF) + (y & 0xFFFF);
  var msw = (x >> 16) + (y >> 16) + (lsw >> 16);
  return (msw << 16) | (lsw & 0xFFFF);
}

/*
 * Bitwise rotate a 32-bit number to the left.
 */
function rol(num, cnt)
{
  return (num << cnt) | (num >>> (32 - cnt));
}

/*
 * Convert an 8-bit or 16-bit string to an array of big-endian words
 * In 8-bit function, characters >255 have their hi-byte silently ignored.
 */
function str2binb(str)
{
  var bin = Array();
  var mask = (1 << chrsz) - 1;
  /* SC - Get rid of warnings */
  for(var i = 0; i < str.length * chrsz; i += chrsz)
  {
    if (bin[i>>5] != undefined)
      bin[i>>5] |= (str.charCodeAt(i / chrsz) & mask) << (32 - chrsz - i%32);
    else
      bin[i>>5]  = (str.charCodeAt(i / chrsz) & mask) << (32 - chrsz - i%32);
  }
  /*for(var i = 0; i < str.length * chrsz; i += chrsz)
      bin[i>>5] |= (str.charCodeAt(i / chrsz) & mask) << (32 - chrsz - i%32);*/
  return bin;
}

/*
 * Convert an array of big-endian words to a string
 */
function binb2str(bin)
{
  var str = "";
  var mask = (1 << chrsz) - 1;
  for(var i = 0; i < bin.length * 32; i += chrsz)
    str += String.fromCharCode((bin[i>>5] >>> (32 - chrsz - i%32)) & mask);
  return str;
}

/*
 * Convert an array of big-endian words to a hex string.
 */
function binb2hex(binarray)
{
  var hex_tab = hexcase ? "0123456789ABCDEF" : "0123456789abcdef";
  var str = "";
  for(var i = 0; i < binarray.length * 4; i++)
  {
    str += hex_tab.charAt((binarray[i>>2] >> ((3 - i%4)*8+4)) & 0xF) +
           hex_tab.charAt((binarray[i>>2] >> ((3 - i%4)*8  )) & 0xF);
  }
  return str;
}

/*
 * Convert an array of big-endian words to a base-64 string
 */
function binb2b64(binarray)
{
  var tab = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  var str = "";
  for(var i = 0; i < binarray.length * 4; i += 3)
  {
    /* SC - Get rid of warning */
    var b1 = binarray[i   >> 2] != undefined ? ((binarray[i   >> 2] >> 8 * (3 -  i   %4)) & 0xFF) << 16 : 0;
    var b2 = binarray[i+1 >> 2] != undefined ? ((binarray[i+1 >> 2] >> 8 * (3 - (i+1)%4)) & 0xFF) << 8  : 0;
    var b3 = binarray[i+2 >> 2] != undefined ? ((binarray[i+2 >> 2] >> 8 * (3 - (i+2)%4)) & 0xFF)       : 0;
    var triplet = b1 | b2 | b3;
    /*var triplet = (((binarray[i   >> 2] >> 8 * (3 -  i   %4)) & 0xFF) << 16)
                | (((binarray[i+1 >> 2] >> 8 * (3 - (i+1)%4)) & 0xFF) << 8 )
                |  ((binarray[i+2 >> 2] >> 8 * (3 - (i+2)%4)) & 0xFF);*/
    for(var j = 0; j < 4; j++)
    {
      if(i * 8 + j * 6 > binarray.length * 32) str += b64pad;
      else str += tab.charAt((triplet >> 6*(3-j)) & 0x3F);
    }
  }
  return str;
}

/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Password Hasher
 *
 * The Initial Developer of the Original Code is Steve Cooper.
 * Portions created by the Initial Developer are Copyright (C) 2006
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s): (none)
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

var PassHashCommon =
{
    // Artificial host name used for for saving to the password database
    host: "passhash.passhash",

    log: function(msg)
    {
        var consoleService = Components.classes["@mozilla.org/consoleservice;1"]
                                .getService(Components.interfaces.nsIConsoleService);
        consoleService.logStringMessage(msg);
    },

    loadOptions: function()
    {
        var opts = this.createOptions();
        var prefs = Components.classes["@mozilla.org/preferences-service;1"].
                        getService(Components.interfaces.nsIPrefService).getBranch("passhash.");
        var forceSave = false;
        if (prefs.prefHasUserValue("optSecurityLevel"))
        {
            opts.securityLevel = prefs.getIntPref("optSecurityLevel");
            opts.firstTime = false;
            forceSave = true;
        }
        if (prefs.prefHasUserValue("optGuessSiteTag"))
            opts.guessSiteTag = prefs.getBoolPref("optGuessSiteTag");
        if (prefs.prefHasUserValue("optRememberSiteTag"))
            opts.rememberSiteTag = prefs.getBoolPref("optRememberSiteTag");
        if (prefs.prefHasUserValue("optRememberMasterKey"))
            opts.rememberMasterKey = prefs.getBoolPref("optRememberMasterKey");
        if (prefs.prefHasUserValue("optRevealSiteTag"))
            opts.revealSiteTag = prefs.getBoolPref("optRevealSiteTag");
        if (prefs.prefHasUserValue("optRevealHashWord"))
            opts.revealHashWord = prefs.getBoolPref("optRevealHashWord");
        if (prefs.prefHasUserValue("optShowMarker"))
            opts.showMarker = prefs.getBoolPref("optShowMarker");
        if (prefs.prefHasUserValue("optUnmaskMarker"))
            opts.unmaskMarker = prefs.getBoolPref("optUnmaskMarker");
        if (prefs.prefHasUserValue("optGuessFullDomain"))
            opts.guessFullDomain = prefs.getBoolPref("optGuessFullDomain");
        if (prefs.prefHasUserValue("optDigitDefault"))
            opts.digitDefault = prefs.getBoolPref("optDigitDefault");
        if (prefs.prefHasUserValue("optPunctuationDefault"))
            opts.punctuationDefault = prefs.getBoolPref("optPunctuationDefault");
        if (prefs.prefHasUserValue("optMixedCaseDefault"))
            opts.mixedCaseDefault = prefs.getBoolPref("optMixedCaseDefault");
        if (prefs.prefHasUserValue("optHashWordSizeDefault"))
            opts.hashWordSizeDefault = prefs.getIntPref("optHashWordSizeDefault");
        if (prefs.prefHasUserValue("optShortcutKeyCode"))
            opts.shortcutKeyCode = prefs.getCharPref("optShortcutKeyCode");
        if (!opts.shortcutKeyCode)
        {
            // Set shortcut key to XUL-defined default.
            forceSave = true;
            var elementKey = document.getElementById("key_passhash");
            if (elementKey != null)
            {
                opts.shortcutKeyCode = elementKey.getAttribute("key");
                if (!opts.shortcutKeyCode)
                    opts.shortcutKeyCode = elementKey.getAttribute("keycode");
            }
        }
        if (prefs.prefHasUserValue("optShortcutKeyMods"))
            opts.shortcutKeyMods = prefs.getCharPref("optShortcutKeyMods");
        if (!opts.shortcutKeyMods)
        {
            // Set shortcut modifiers to XUL-defined default.
            forceSave = true;
            var elementKey = document.getElementById("key_passhash");
            if (elementKey != null)
                opts.shortcutKeyMods = elementKey.getAttribute("modifiers");
        }
        // Force saving options if the key options are not present to give them visibility
        if (forceSave)
            this.saveOptions(opts);
        return opts;
    },

    createOptions: function()
    {
        var opts = new Object();
        opts.securityLevel       = 2;
        opts.guessSiteTag        = true;
        opts.rememberSiteTag     = true;
        opts.rememberMasterKey   = false;
        opts.revealSiteTag       = true;
        opts.revealHashWord      = false;
        opts.showMarker          = true;
        opts.unmaskMarker        = false;
        opts.guessFullDomain     = false;
        opts.digitDefault        = true;
        opts.punctuationDefault  = true;
        opts.mixedCaseDefault    = true;
        opts.hashWordSizeDefault = 8;
        opts.firstTime           = true;
        opts.shortcutKeyCode     = "";
        opts.shortcutKeyMods     = "";
        return opts;
    },

    saveOptions: function(opts)
    {
        var prefs = Components.classes["@mozilla.org/preferences-service;1"].
                        getService(Components.interfaces.nsIPrefService).getBranch("passhash.");
        prefs.setIntPref( "optSecurityLevel",       opts.securityLevel);
        prefs.setBoolPref("optGuessSiteTag",        opts.guessSiteTag);
        prefs.setBoolPref("optRememberSiteTag",     opts.rememberSiteTag);
        prefs.setBoolPref("optRememberMasterKey",   opts.rememberMasterKey);
        prefs.setBoolPref("optRevealSiteTag",       opts.revealSiteTag);
        prefs.setBoolPref("optRevealHashWord",      opts.revealHashWord);
        prefs.setBoolPref("optShowMarker",          opts.showMarker);
        prefs.setBoolPref("optUnmaskMarker",        opts.unmaskMarker);
        prefs.setBoolPref("optGuessFullDomain",     opts.guessFullDomain);
        prefs.setBoolPref("optDigitDefault",        opts.digitDefault);
        prefs.setBoolPref("optPunctuationDefault",  opts.punctuationDefault);
        prefs.setBoolPref("optMixedCaseDefault",    opts.mixedCaseDefault);
        prefs.setIntPref( "optHashWordSizeDefault", opts.hashWordSizeDefault);
        prefs.setCharPref("optShortcutKeyCode",     opts.shortcutKeyCode);
        prefs.setCharPref("optShortcutKeyMods",     opts.shortcutKeyMods);
    },

    loadSecureValue: function(option, name, suffix, valueDefault)
    {
        return (this.hasLoginManager()
                    ? this.loadLoginManagerValue(option, name, suffix, valueDefault)
                    : this.loadPasswordManagerValue(option, name, suffix, valueDefault));
    },

    loadLoginManagerValue: function(option, name, suffix, valueDefault)
    {
        var user = (suffix ? name + "-" + suffix : name);
        var value = valueDefault;
        if (option && suffix != null)
        {
            var login = this.findLoginManagerUserLogin(user);
            if (login != null && login.password != "" && login.password != "n/a")
                value = login.password;
        }
        return value;
    },

    loadPasswordManagerValue: function(option, name, suffix, valueDefault)
    {
        var user = (suffix ? name + "-" + suffix : name);
        var value = valueDefault;
        var found = false;
        if (option && suffix != null)
        {
            var passwordManager = Components.classes["@mozilla.org/passwordmanager;1"]
                                            .getService(Components.interfaces.nsIPasswordManager);
            var e = passwordManager.enumerator;
            while (!found && e.hasMoreElements())
            {
                try
                {
                    var pass = e.getNext().QueryInterface(Components.interfaces.nsIPassword);
                    if (pass.host == this.host && pass.user == user)
                    {
                         value = pass.password;
                         found = true;
                    }
                }
                catch (ex) {}
            }
        }
        return value;
    },

    saveSecureValue: function(option, name, suffix, value)
    {
        return (this.hasLoginManager()
                    ? this.saveLoginManagerValue(option, name, suffix, value)
                    : this.savePasswordManagerValue(option, name, suffix, value));
    },

    saveLoginManagerValue: function(option, name, suffix, value)
    {
        if (!value || suffix == null)
            return false;
        var valueSave = (option ? value : "n/a");
        var user = (suffix ? name + "-" + suffix : name);

        var loginManager = Components.classes["@mozilla.org/login-manager;1"].
                                getService(Components.interfaces.nsILoginManager);

        var newLogin = Components.classes["@mozilla.org/login-manager/loginInfo;1"].
                                createInstance(Components.interfaces.nsILoginInfo);

        newLogin.init(this.host, 'passhash', null, user, valueSave, "", "");

        var currentLogin = this.findLoginManagerUserLogin(user);

        if ( currentLogin == null)
            loginManager.addLogin(newLogin);
        else
            loginManager.modifyLogin(currentLogin, newLogin);
        return true;
    },

    savePasswordManagerValue: function(option, name, suffix, value)
    {
        if (!value || suffix == null)
            return false;
        var valueSave = (option ? value : "");
        var user = (suffix ? name + "-" + suffix : name);
        var passwordManager = Components.classes["@mozilla.org/passwordmanager;1"]
                                        .getService(Components.interfaces.nsIPasswordManager);
        try
        {
            // Firefox 2 seems to lose info from subsequent addUser calls
            // addUser on an existing host/user after restarting.
            passwordManager.removeUser(this.host, user);
        }
        catch (ex) {}
        passwordManager.addUser(this.host, user, valueSave);
        return true;
    },

    hasLoginManager: function()
    {
        return ("@mozilla.org/login-manager;1" in Components.classes);
    },

    findLoginManagerUserLogin: function(user)
    {
        // Find user from returned array of nsILoginInfo objects
        var logins = this.findAllLoginManagerLogins();
        for (var i = 0; i < logins.length; i++)
            if (logins[i].username == user)
                return logins[i];
        return null;
    },

    findAllLoginManagerLogins: function()
    {
        var loginManager = Components.classes["@mozilla.org/login-manager;1"].
                                getService(Components.interfaces.nsILoginManager);
        return loginManager.findLogins({}, this.host, "passhash", null);
    },

    // TODO: There's probably a better way
    getDomain: function(input)
    {
        var h = input.host.split(".");
        if (h.length <= 1)
            return null;
        // Handle domains like co.uk
        if (h.length > 2 && h[h.length-1].length == 2 && h[h.length-2] == "co")
            return h[h.length-3] + '.' + h[h.length-2] + '.' + h[h.length-1];
        return h[h.length-2] + '.' + h[h.length-1];
    },

    // IMPORTANT: This function should be changed carefully.  It must be
    // completely deterministic and consistent between releases.  Otherwise
    // users would be forced to update their passwords.  In other words, the
    // algorithm must always be backward-compatible.  It's only acceptable to
    // violate backward compatibility when new options are used.
    // SECURITY: The optional adjustments are positioned and calculated based
    // on the sum of all character codes in the raw hash string.  So it becomes
    // far more difficult to guess the injected special characters without
    // knowing the master key.
    // TODO: Is it ok to assume ASCII is ok for adjustments?
    generateHashWord: function(
                siteTag,
                masterKey,
                hashWordSize,
                requireDigit,
                requirePunctuation,
                requireMixedCase,
                restrictSpecial,
                restrictDigits)
    {
        // Start with the SHA1-encrypted master key/site tag.
        var s = b64_hmac_sha1(masterKey, siteTag);
        // Use the checksum of all characters as a pseudo-randomizing seed to
        // avoid making the injected characters easy to guess.  Note that it
        // isn't random in the sense of not being deterministic (i.e.
        // repeatable).  Must share the same seed between all injected
        // characters so that they are guaranteed unique positions based on
        // their offsets.
        var sum = 0;
        for (var i = 0; i < s.length; i++)
            sum += s.charCodeAt(i);
        // Restrict digits just does a mod 10 of all the characters
        if (restrictDigits)
            s = PassHashCommon.convertToDigits(s, sum, hashWordSize);
        else
        {
            // Inject digit, punctuation, and mixed case as needed.
            if (requireDigit)
                s = PassHashCommon.injectSpecialCharacter(s, 0, 4, sum, hashWordSize, 48, 10);
            if (requirePunctuation && !restrictSpecial)
                s = PassHashCommon.injectSpecialCharacter(s, 1, 4, sum, hashWordSize, 33, 15);
            if (requireMixedCase)
            {
                s = PassHashCommon.injectSpecialCharacter(s, 2, 4, sum, hashWordSize, 65, 26);
                s = PassHashCommon.injectSpecialCharacter(s, 3, 4, sum, hashWordSize, 97, 26);
            }
            // Strip out special characters as needed.
            if (restrictSpecial)
                s = PassHashCommon.removeSpecialCharacters(s, sum, hashWordSize);
        }
        // Trim it to size.
        return s.substr(0, hashWordSize);
    },

    // This is a very specialized method to inject a character chosen from a
    // range of character codes into a block at the front of a string if one of
    // those characters is not already present.
    // Parameters:
    //  sInput   = input string
    //  offset   = offset for position of injected character
    //  reserved = # of offsets reserved for special characters
    //  seed     = seed for pseudo-randomizing the position and injected character
    //  lenOut   = length of head of string that will eventually survive truncation.
    //  cStart   = character code for first valid injected character.
    //  cNum     = number of valid character codes starting from cStart.
    injectSpecialCharacter: function(sInput, offset, reserved, seed, lenOut, cStart, cNum)
    {
        var pos0 = seed % lenOut;
        var pos = (pos0 + offset) % lenOut;
        // Check if a qualified character is already present
        // Write the loop so that the reserved block is ignored.
        for (var i = 0; i < lenOut - reserved; i++)
        {
            var i2 = (pos0 + reserved + i) % lenOut
            var c = sInput.charCodeAt(i2);
            if (c >= cStart && c < cStart + cNum)
                return sInput;  // Already present - nothing to do
        }
        var sHead   = (pos > 0 ? sInput.substring(0, pos) : "");
        var sInject = String.fromCharCode(((seed + sInput.charCodeAt(pos)) % cNum) + cStart);
        var sTail   = (pos + 1 < sInput.length ? sInput.substring(pos+1, sInput.length) : "");
        return (sHead + sInject + sTail);
    },

    // Another specialized method to replace a class of character, e.g.
    // punctuation, with plain letters and numbers.
    // Parameters:
    //  sInput = input string
    //  seed   = seed for pseudo-randomizing the position and injected character
    //  lenOut = length of head of string that will eventually survive truncation.
    removeSpecialCharacters: function(sInput, seed, lenOut)
    {
        var s = '';
        var i = 0;
        while (i < lenOut)
        {
            var j = sInput.substring(i).search(/[^a-z0-9]/i);
            if (j < 0)
                break;
            if (j > 0)
                s += sInput.substring(i, i + j);
            s += String.fromCharCode((seed + i) % 26 + 65);
            i += (j + 1);
        }
        if (i < sInput.length)
            s += sInput.substring(i);
        return s;
    },

    // Convert input string to digits-only.
    // Parameters:
    //  sInput = input string
    //  seed   = seed for pseudo-randomizing the position and injected character
    //  lenOut = length of head of string that will eventually survive truncation.
    convertToDigits: function(sInput, seed, lenOut)
    {
        var s = '';
        var i = 0;
        while (i < lenOut)
        {
            var j = sInput.substring(i).search(/[^0-9]/i);
            if (j < 0)
                break;
            if (j > 0)
                s += sInput.substring(i, i + j);
            s += String.fromCharCode((seed + sInput.charCodeAt(i)) % 10 + 48);
            i += (j + 1);
        }
        if (i < sInput.length)
            s += sInput.substring(i);
        return s;
    },

    bumpSiteTag: function(siteTag)
    {
        var tag = siteTag.replace(/^[ \t]*(.*)[ \t]*$/, "$1");    // redundant
        if (tag)
        {
            var splitTag = tag.match(/^(.*):([0-9]+)?$/);
            if (splitTag == null || splitTag.length < 3)
                tag += ":1";
            else
                tag = splitTag[1] + ":" + (parseInt(splitTag[2]) + 1);
        }
        return tag;
    },

    // Returns true if an HTML node is some kind of text field.
    isTextNode: function(node)
    {
        try
        {
            var name = node.localName.toUpperCase();
            if (name == "TEXTAREA" || name == "TEXTBOX" ||
                        (name == "INPUT" &&
                            (node.type == "text" || node.type == "password")))
                return true;
        }
        catch(e) {}
        return false;
    },

    // From Mozilla utilityOverlay.js
    // TODO: Can I access it directly?
    openUILinkIn: function(url, where)
    {
        if (!where)
            return;

        if ((url == null) || (url == ""))
            return;

        // xlate the URL if necessary
        if (url.indexOf("urn:") == 0)
            url = xlateURL(url);        // does RDF urn expansion

        // avoid loading "", since this loads a directory listing
        if (url == "")
            url = "about:blank";

        if (where == "save")
        {
            saveURL(url, null, null, true);
            return;
        }

        var w = (where == "window") ? null : this.getTopWin();
        if (!w)
        {
            openDialog(getBrowserURL(), "_blank", "chrome,all,dialog=no", url);
            return;
        }
        var browser = w.document.getElementById("content");

        switch (where)
        {
            case "current":
                browser.loadURI(url);
                w.content.focus();
                break;
            case "tabshifted":
            case "tab":
                var tab = browser.addTab(url);
                if ((where == "tab") ^ this.getBoolPref("browser.tabs.loadBookmarksInBackground",
                                                        false))
                {
                    browser.selectedTab = tab;
                    w.content.focus();
                }
                break;
        }
    },

    // From Mozilla utilityOverlay.js
    getTopWin: function()
    {
        var windowManager = Components.classes['@mozilla.org/appshell/window-mediator;1'].
                                getService();
        var windowManagerInterface = windowManager.QueryInterface(
                                        Components.interfaces.nsIWindowMediator);
        var topWindowOfType = windowManagerInterface.getMostRecentWindow("navigator:browser");

        if (topWindowOfType)
            return topWindowOfType;

        return null;
    },

    // From Mozilla utilityOverlay.js
    getBoolPref: function(prefname, def)
    {
        try
        {
            var pref = Components.classes["@mozilla.org/preferences-service;1"]
                           .getService(Components.interfaces.nsIPrefBranch);
            return pref.getBoolPref(prefname);
        }
        catch(ex)
        {
            return def;
        }
    },

    // Build an array sorted by domain name with properties populated, as
    // available, for site tag, master key and options.
    getSavedEntries: function()
    {
        // Because of Javascript limitations on associative arrays, e.g. not
        // handling non-alphanumeric,  we'll go to the trouble of building
        // separate sortable arrays of site tags, master keys and options using
        // domain/value objects.  After sorting the three arrays we can walk
        // through them and build the returned array of fully-fleshed-out
        // objects.
        var siteTags   = new Array();
        var masterKeys = new Array();
        var options    = new Array();
        if (this.hasLoginManager())
            this.getAllLoginManagerEntries(siteTags, masterKeys, options);
        else
            this.getAllPasswordManagerEntries(siteTags, masterKeys, options);

        var entries = Array();
        siteTags.sort(  function(a, b) {return a.name.localeCompare(b.name);});
        masterKeys.sort(function(a, b) {return a.name.localeCompare(b.name);});
        options.sort(   function(a, b) {return a.name.localeCompare(b.name);});
        var iSiteTag = 0, iMasterKey = 0, iOption = 0;
        while (iSiteTag   <   siteTags.length ||
               iMasterKey < masterKeys.length ||
               iOption    <    options.length)
        {
            // Find the lowest domain name from the three waiting values
            var next = null;
            if (iSiteTag < siteTags.length && (next == null ||
                siteTags[iSiteTag].name < next))
                next = siteTags[iSiteTag].name;
            if (iMasterKey < masterKeys.length && (next == null ||
                masterKeys[iMasterKey].name < next))
                next = masterKeys[iMasterKey].name;
            if (iOption < options.length && (next == null ||
                options[iOption].name < next))
                next = options[iOption].name;
            // Grab all data with a matching domain name and advance the corresponding index
            entries[entries.length] = {name: next};
            if (iSiteTag < siteTags.length && next == siteTags[iSiteTag].name)
            {
                entries[entries.length-1].siteTag = siteTags[iSiteTag].value;
                iSiteTag++;
            }
            else
                entries[entries.length-1].siteTag = "";
            if (iMasterKey < masterKeys.length && next == masterKeys[iMasterKey].name)
            {
                entries[entries.length-1].masterKey = masterKeys[iMasterKey].value;
                iMasterKey++;
            }
            else
                entries[entries.length-1].masterKey = "";
            if (iOption < options.length && next == options[iOption].name)
            {
                entries[entries.length-1].options = options[iOption].value;
                iOption++;
            }
            else
                entries[entries.length-1].options = "";
        }
        return entries;
    },

    // Gather all extension-related FF3 login manager entries.  Return as 3
    // arrays for site tags, master keys and options.
    getAllLoginManagerEntries: function(siteTags, masterKeys, options)
    {
        var logins = this.findAllLoginManagerLogins();
        for (var i = 0; i < logins.length; i++)
        {
            var login = logins[i];
            try
            {
                if (login.hostname == this.host)
                {
                    if (login.username.indexOf("site-tag-") == 0)
                    {
                        var o = new Object();
                        o.name = login.username.substring(9);
                        o.value = login.password;
                        siteTags[siteTags.length] = o;
                    }
                    else
                    {
                        if (login.username.indexOf("master-key-") == 0)
                        {
                            var o = new Object();
                            o.name = login.username.substring(11);
                            o.value = login.password;
                            masterKeys[masterKeys.length] = o;
                        }
                        else
                        {
                            if (login.username.indexOf("options-") == 0)
                            {
                                var o = new Object();
                                o.name = login.username.substring(8);
                                o.value = login.password;
                                options[options.length] = o;
                            }
                        }
                    }
                }
            }
            catch(e) {}
        }
    },

    // Gather all extension-related FF2 login manager entries.  Return as 3
    // arrays for site tags, master keys and options.
    getAllPasswordManagerEntries: function(siteTags, masterKeys, options)
    {
        var passwordManager = Components.classes["@mozilla.org/passwordmanager;1"].
                                    createInstance();
        passwordManager.QueryInterface(Components.interfaces.nsIPasswordManager);
        passwordManager.QueryInterface(Components.interfaces.nsIPasswordManagerInternal);
        var passwordEnumerator = passwordManager.enumerator;
        while(passwordEnumerator.hasMoreElements())
        {
            try
            {
                var pw = passwordEnumerator.getNext()
                        .QueryInterface(Components.interfaces.nsIPasswordInternal);
                if (pw.host == this.host)
                {
                    if (pw.user.indexOf("site-tag-") == 0)
                    {
                        var o = new Object();
                        o.name = pw.user.substring(9);
                        o.value = pw.password;
                        siteTags[siteTags.length] = o;
                    }
                    else
                    {
                        if (pw.user.indexOf("master-key-") == 0)
                        {
                            var o = new Object();
                            o.name = pw.user.substring(11);
                            o.value = pw.password;
                            masterKeys[masterKeys.length] = o;
                        }
                        else
                        {
                            if (pw.user.indexOf("options-") == 0)
                            {
                                var o = new Object();
                                o.name = pw.user.substring(8);
                                o.value = pw.password;
                                options[options.length] = o;
                            }
                        }
                    }
                }
            }
            catch(e) {}
        }
    },

    getResourceFile: function(uri)
    {
        var handler = Components.classes["@mozilla.org/network/protocol;1?name=file"]
                            .createInstance(Components.interfaces.nsIFileProtocolHandler);
        var urlSrc = Components.classes["@mozilla.org/network/standard-url;1"]
                            .createInstance( Components.interfaces.nsIURL );
        urlSrc.spec = uri;
        var chromeReg = Components.classes["@mozilla.org/chrome/chrome-registry;1"]
                            .getService( Components.interfaces.nsIChromeRegistry );
        var urlIn = chromeReg.convertChromeURL(urlSrc);
        return handler.getFileFromURLSpec(urlIn.spec);
    },

    openInputFile: function(fileIn)
    {
        var streamIn = Components.classes["@mozilla.org/network/file-input-stream;1"]
                            .createInstance(Components.interfaces.nsIFileInputStream);
        streamIn.init(fileIn, 0x01, 0444, 0);
        streamIn.QueryInterface(Components.interfaces.nsILineInputStream);
        return streamIn;
    },

    openOutputFile: function(fileOut)
    {
        var streamOut = Components.classes["@mozilla.org/network/file-output-stream;1"]
                                 .createInstance(Components.interfaces.nsIFileOutputStream);
        streamOut.init(fileOut, 0x02 | 0x08 | 0x20, 0664, 0); // write, create, truncate
        return streamOut;
    },

    streamWriteLine: function(stream, line)
    {
        stream.write(line, line.length);
        stream.write("\n", 1);
    },

    // Expand variables and return resulting string
    expandLine: function(lineIn)
    {
        var strings = document.getElementById("pshOpt_strings");
        var lineOut = "";
        var splicePos = 0;
        var re = /[$][{][ \t]*([^ }]+)[^}]*[}]/g;
        var match;
        while ((match = re.exec(lineIn)) != null)
        {
            lineOut += lineIn.substr(splicePos, match.index);
            try
            {
                lineOut += strings.getString(match[1]);
            }
            catch (ex)
            {
                alert("Couldn't find string \"" + match[1] + "\"");
                lineOut += "???" + match[1] + "???";
            }
            splicePos = re.lastIndex;
        }
        lineOut += lineIn.substr(splicePos);
        return lineOut;
    },

    // Expand variables and write line to output stream
    streamWriteExpandedLine: function(stream, line)
    {
        PassHashCommon.streamWriteLine(stream, PassHashCommon.expandLine(line));
    },

    browseFile: function(file, where)
    {
        var handler = Components.classes["@mozilla.org/network/protocol;1?name=file"]
                            .createInstance(Components.interfaces.nsIFileProtocolHandler);
        PassHashCommon.openUILinkIn(handler.getURLSpecFromFile(file), where);
    },

    pickHTMLFile: function(titleTag, defaultName)
    {
        var title = document.getElementById("pshOpt_strings").getString(titleTag);
        var nsIFilePicker = Components.interfaces.nsIFilePicker;
        var picker = Components.classes["@mozilla.org/filepicker;1"].createInstance(nsIFilePicker);
        if (defaultName)
            picker.defaultString = defaultName;
        picker.appendFilters(nsIFilePicker.filterHTML);
        picker.init(window, title, nsIFilePicker.modeSave);
        var file;
        do
        {
            var action = picker.show();
            if (action == 1)
                return null;
            file = picker.file;
            if (! /\.html{0,1}$/.test(picker.file.path))
                file.initWithPath(picker.file.path + ".html");
            picker.defaultString = file.leafName;
        }
        while (file.exists() && (action == 0));
        return file;
    },
}
