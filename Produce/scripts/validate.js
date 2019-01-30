var validate = new function () {
    'use strict';

    var invalidAttribute = 'aria-invalid';
    var invalidAttributeDesc = 'aria-describedby';
    var dayCount = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    var dateTerms = ['today', 'tomorrow', 'yesterday'];
    var monthTerms = JSON.parse($('#validateMonths').val());

    var valNumber = $('#validateNumber').val();
    var valDate = $('#validateDate').val();
    var valMandatory = $('#validateRequired').val();

    this.checkMandatory = function checkMandatory(qid, minusOneIsEmpty) {
        var selector = '#' + qid;
        var val = $(selector).val();
        val = (minusOneIsEmpty && val === '-1' ? '' : val);
        if (val === '') {
            var currentError = $('#error_' + qid).html();
            if (currentError === undefined || currentError.trim() !== valMandatory) {
                this.setFail(selector);
            }
            return false;
        } else {
            this.setPass(selector);
            return true;
        }
    }

    this.currencyCheck = function currencyCheck(qid, currencySymbol, decimalSymbol) {
        var selector = '#' + qid;
        var val = $(selector).val();
        if (val !== '' && wiz.removeCurrencyFormat($(selector).val(), currencySymbol, decimalSymbol) === '') {
            this.setFail(selector, valNumber);
            return false;
        } else {
            this.setPass(selector);
            return true;
        }
    }

    this.numberCheck = function numberCheck(qid) {
        var selector = '#' + qid;
        var val = $(selector).val();
        if (val !== '' && !$.isNumeric(val)) {
            this.setFail(selector, valNumber);
            return false;
        } else {
            this.setPass(selector);
            return true;
        }
    }

    this.setPass = function setPass(selector) {
        $(selector).removeAttr(invalidAttribute);
        $(selector).removeAttr(invalidAttributeDesc);
        $('[id^=' + selector.replace('#', 'error_') + ']').remove();
    }

    this.setFail = function setFail(selector, message, messageSelector) {
        this.setPass(selector);

        if (message !== undefined) {
            var qid = selector.substr(1);
            var errorId = 'error_' + qid;
            if (messageSelector === undefined) {
                messageSelector = selector;
            }
            $('<span class="wrn" id="' + errorId + '" data-focus="' + qid + '">' + message + '</span>').insertAfter(messageSelector);
            $(selector).attr(invalidAttribute, "true");
            $(selector).attr(invalidAttributeDesc, errorId);
        }
        else {
            $(selector).attr(invalidAttribute, "true");
        }
    }

    this.getNextInterval = function getNextInterval(intervalOrder, currentInterval) {
        currentInterval = currentInterval.substr(0, 1);
        for (var i = 0; i < intervalOrder.length; i++) {
            if (intervalOrder[i].indexOf(currentInterval) === 0) {
                if (i < intervalOrder.length - 1) {
                    var nextInterval = intervalOrder[i + 1];
                    if (nextInterval.indexOf('y') === 0) {
                        return 'yyyy';
                    } else if (nextInterval.indexOf('M') === 0) {
                        return 'MM';
                    } else {
                        return 'dd';
                    }
                }
                break;
            }
        }
        return undefined;
    }

    this.isPendingInterval = function isPendingInterval(intervalOrder, currentInterval, checkInterval) {
        if (currentInterval === undefined || currentInterval === checkInterval) {
            return true;
        }
        currentInterval = currentInterval.substr(0, 1);
        checkInterval = checkInterval.substr(0, 1);
        var currentIntervalPos = -1;
        var checkIntervalPos = -1;
        for (var i = 0; i < intervalOrder.length; i++) {
            if (intervalOrder[i].indexOf(currentInterval) === 0) {
                currentIntervalPos = i;
                if (checkIntervalPos !== -1) {
                    break;
                }
            } else if (intervalOrder[i].indexOf(checkInterval) === 0) {
                checkIntervalPos = i;
                if (currentIntervalPos !== -1) {
                    break;
                }
            }
        }
        return checkIntervalPos <= currentIntervalPos;
    }

    this.intervalKeyUp = function intervalKeyUp(e, qid, intervalOrder, interval) {
        if ((e.keyCode >= '48' && e.keyCode <= '57') || (e.keyCode >= '96' && e.keyCode <= '105') || (e.keyCode === 229 /* Android */)) {
            var nextInterval = this.intervalFormat(qid, intervalOrder, interval, false);
            if (nextInterval !== undefined) {
                $('#' + qid + '_' + nextInterval).select();
            }
        }
    }

    this.intervalFormat = function intervalFormat(qid, intervalOrder, interval, isBlur) {
        var selector = '#' + qid + '_' + interval;
        var val = $(selector).val();
        if ($.isNumeric(val)) {
            var moveNext = false;
            if (interval !== 'yyyy') {
                var tenBound;
                var max;
                if (interval === 'dd') {
                    tenBound = 3;
                    max = 31;
                } else {
                    tenBound = 1;
                    max = 12;
                }

                if (val.length === 2 && val >= tenBound && val <= max) {
                    if (val.indexOf('0') === 0 && $.inArray(interval, intervalOrder) === -1) {
                        $(selector).val(val.substr(1, 1));
                    }
                    moveNext = true;
                } else if (val.length === 1 && val > tenBound && val <= 9) {
                    if ($.inArray(interval, intervalOrder) !== -1) {
                        $(selector).val('0' + val);
                    }
                    moveNext = true;
                }
            } else {
                if (val.length === 4) {
                    moveNext = true;
                } else if (val.length === 2) {
                    var currentYearFourDigit = new Date().getFullYear();
                    if (isBlur) {
                        $(selector).val(this.convertTwoDigitYear(currentYearFourDigit, val));
                    } else {
                        var centuries = [currentYearFourDigit.toString().substr(0, 2), (currentYearFourDigit - 100).toString().substr(0, 2), (currentYearFourDigit + 100).toString().substr(0, 2)];
                        if ($.inArray(val, centuries) === -1) {
                            $(selector).val(this.convertTwoDigitYear(currentYearFourDigit, val));
                            moveNext = true;
                        }
                    }
                }
            }
            if (!isBlur && moveNext) {
                return this.getNextInterval(intervalOrder, interval);
            }
        }

        return undefined;
    }

    this.convertTwoDigitYear = function convertTwoDigitYear(currentYearFourDigit, twoDigitYear) {
        for (var y = currentYearFourDigit; y <= currentYearFourDigit + 11; y++) {
            if (twoDigitYear === y.toString().substr(2, 2)) {
                //Future Date
                return y.toString();
            }
        }
        //Past Date
        var userYearTwoDigit = parseInt(twoDigitYear)
        var currentYearTwoDigit = parseInt(currentYearFourDigit.toString().substr(2, 2));
        var currentCenturyStart = currentYearFourDigit - currentYearTwoDigit;
        var userYearFourDigit = currentCenturyStart + userYearTwoDigit;
        if (currentYearTwoDigit - userYearTwoDigit < 0) {
            userYearFourDigit = userYearFourDigit - 100;
        }
        return userYearFourDigit.toString();
    }

    this.dateIntervalValidate = function dateIntervalValidate(qid, interval, intervalOrder, isMandatory, year, month, day) {
        var validYear = true;
        var validMonth = true;
        var validDay = true;
        var selector = '#' + qid;

        if (interval !== undefined) {
            this.setPass(selector + '_yyyy');
            this.setPass(selector + '_MM');
            this.setPass(selector + '_dd');
        } else {
            this.setPass(selector);
        }

        if (!$.isNumeric(year) || year.length !== 4) {
            validYear = false;
        }

        if ($.isNumeric(month)) {
            if (!(month > 0 && month <= 12)) {
                validMonth = false;
            }
        } else if (monthTerms.indexOf(month.toLowerCase()) === -1) {
            validMonth = false;
        }

        if (!$.isNumeric(day) || !(day > 0 && day <= 31)) {
            validDay = false;
        }

        if (validDay && validMonth && day >= 28) {
            if (day > dayCount[month - 1]) {
                if (validYear && parseInt(month) === 2 && parseInt(day) === 29) {
                    if ((!(year % 4) && year % 100) || !(year % 400)) {
                        //leap year
                    } else {
                        validDay = false;
                        validYear = false;
                    }
                } else {
                    validDay = false;
                }
            }
        }

        if (validYear && validMonth && validDay) {
            return true;
        } else {
            if (interval !== undefined) {
                if (!validYear && this.isPendingInterval(intervalOrder, interval, 'yyyy')) {
                    this.setDateValidation(qid, 'yyyy', year, isMandatory);
                }
                if (!validMonth && this.isPendingInterval(intervalOrder, interval, 'MM')) {
                    this.setDateValidation(qid, 'MM', month, isMandatory);
                }
                if (!validDay && this.isPendingInterval(intervalOrder, interval, 'dd')) {
                    this.setDateValidation(qid, 'dd', day, isMandatory);
                }
            } else {
                this.setDateValidation(qid, undefined, year + month + day, isMandatory);
            }

            if (year + month + day === '' && !isMandatory) {
                return true;
            }
            else {
                return false;
            }
        }
    }

    this.setDateValidation = function setDateValidation(qid, interval, value, isMandatory) {
        var baseSelector = '#' + qid;
        var fieldSelector = baseSelector + (interval === undefined ? '' : '_' + interval);
        if (value !== '') {
            if (interval !== undefined) {
                this.setPass(baseSelector);
            }
            this.setFail(fieldSelector, valDate, baseSelector + '_grp');
        } else if (isMandatory) {
            this.setFail(fieldSelector);
        }
    }

    this.dateStringValidate = function dateStringValidate(qid, intervalOrder, isMandatory) {
        var selector = '#' + qid;
        var dateString = $(selector).val();
        var dateSplit = dateString.split(/\/|-| |\./);

        if (dateSplit.length === 3) {
            var year;
            var month;
            var day;

            for (var i = 0; i < intervalOrder.length; i++) {
                if (intervalOrder[i].indexOf('y') === 0) {
                    year = dateSplit[i];
                } else if (intervalOrder[i].indexOf('M') === 0) {
                    month = dateSplit[i];
                } else {
                    day = dateSplit[i];
                }
            }

            if ($.isNumeric(year) && year.length === 2) {

                var separators = dateString.replace(/[0-9]/g, '');
                if (separators.length === 2 && separators[0] === separators[1]) {
                    year = this.convertTwoDigitYear(new Date().getFullYear(), year);
                    var separator = separators[0];
                    var format = intervalOrder.map(function (x) { return x.substr(0, 1); }).join(separator);
                    format = format.replace("y", year);
                    format = format.replace("M", month);
                    format = format.replace("d", day);
                    $(selector).val(format);
                }
            }

            return this.dateIntervalValidate(qid, undefined, intervalOrder, isMandatory, year, month, day);
        } if (dateSplit.length === 1) {
            if (dateSplit[0] === '') {
                return this.dateIntervalValidate(qid, undefined, intervalOrder, isMandatory, '', '', '');
            } else if (dateTerms.indexOf(dateSplit[0].toLowerCase()) === -1) {
                return this.dateIntervalValidate(qid, undefined, intervalOrder, isMandatory, dateSplit[0], '', '');
            } else {
                this.setPass(selector);
                return true;
            }
        } else if (dateSplit.length === 2) {
            var fullYear = new Date().getFullYear().toString();
            for (var i = 0; i < intervalOrder.length; i++) {
                if (intervalOrder[i].indexOf('M') === 0) {
                    return this.dateIntervalValidate(qid, undefined, intervalOrder, isMandatory, fullYear, dateSplit[0], dateSplit[1]);
                } else if (intervalOrder[i].indexOf('d') === 0) {
                    return this.dateIntervalValidate(qid, undefined, intervalOrder, isMandatory, fullYear, dateSplit[1], dateSplit[0]);
                }
            }
        } else {
            this.setFail(selector, valDate, selector + '_grp');
            return false;
        }
    }
}
