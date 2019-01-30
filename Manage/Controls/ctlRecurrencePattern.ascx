<%@ Reference Control="~/Controls/ctlDate.ascx" %>
<%@ Register TagPrefix="uc1" TagName="ctlDate" Src="ctlDate.ascx" %>
<%@ Control Language="vb" AutoEventWireup="false" Inherits="Intelledox.Manage.ctlRecurrencePattern" enableViewState="True" Codebehind="ctlRecurrencePattern.ascx.vb" %>
<input id="RecurrencePatternID" type="hidden" runat="server">
<table cellSpacing="0" border="1" role="presentation">
    <tr>
        <td class="base3 titlerow" colSpan="2"><%= Resources.Strings.RecurrencePattern%></td>
    </tr>
    <tr>
        <td vAlign="top">
            <asp:radiobutton id="optMinutely" runat="server" GroupName="RecurrenceType" Text="<%$Resources:Strings, Minutely%>"></asp:radiobutton><br>
            <asp:radiobutton id="optHourly" runat="server" GroupName="RecurrenceType" Text="<%$Resources:Strings, Hourly%>"></asp:radiobutton><br>
            <asp:radiobutton id="optDaily" runat="server" GroupName="RecurrenceType" Text="<%$Resources:Strings, Daily%>"></asp:radiobutton><br>
            <asp:radiobutton id="optWeekly" runat="server" GroupName="RecurrenceType" Text="<%$Resources:Strings, Weekly%>"></asp:radiobutton><br>
            <asp:radiobutton id="optMonthly" runat="server" GroupName="RecurrenceType" Text="<%$Resources:Strings, Monthly%>"></asp:radiobutton><br>
            <asp:radiobutton id="optYearly" runat="server" GroupName="RecurrenceType" Text="<%$Resources:Strings, Yearly%>"></asp:radiobutton></td>
        <td vAlign="top">
            <table id="MinutelyTable" style="display: none" role="presentation">
                <tr>
                    <td><%=Resources.Strings.Every%>&nbsp;
                        <asp:textbox id="txtMinutelyEvery" runat="server" Width="40px" CssClass="fld">5</asp:textbox>&nbsp;<%=Resources.Strings.Minutes%></td>
                </tr>
            </table>
            <table id="HourlyTable" style="display: none" role="presentation">
                <tr>
                    <td><%=Resources.Strings.Every%>&nbsp;
                        <asp:textbox id="txtHourlyEvery" runat="server" Width="40px" CssClass="fld">1</asp:textbox>&nbsp;<%=Resources.Strings.Hours%></td>
                </tr>
            </table>
            <table id="DailyTable" style="display: none" role="presentation">
                <tr>
                    <td><asp:radiobutton id="optDailyEvery" runat="server" GroupName="DailyType" Text="<%$Resources:Strings, Every%>" Checked="True"></asp:radiobutton>&nbsp;
                        <asp:textbox id="txtDailyEveryDay" runat="server" Width="40px" CssClass="fld">1</asp:textbox>&nbsp;<%= Resources.Strings.Days%></td>
                </tr>
                <tr>
                    <td><asp:radiobutton id="optDailyWeekday" runat="server" GroupName="DailyType" Text="<%$Resources:Strings, Everyweekday%>"></asp:radiobutton></td>
                </tr>
            </table>
            <table id="WeeklyTable" role="presentation">
                <tr>
                    <td colSpan="4"><%= Resources.Strings.RecurEvery%>&nbsp;
                        <asp:textbox id="txtWeeklyEveryDay" runat="server" Width="40px" CssClass="fld">1</asp:textbox>&nbsp;<%=Resources.Strings.WeeksOn %>:
                        </td>
                </tr>
                <tr>
                    <td><asp:checkbox id="chkMonday" runat="server" Text="<%$Resources:Strings, Monday%>" Checked="True"></asp:checkbox></td>
                    <td><asp:checkbox id="chkTuesday" runat="server" Text="<%$Resources:Strings, Tuesday%>"></asp:checkbox></td>
                    <td><asp:checkbox id="chkWednesday" runat="server" Text="<%$Resources:Strings, Wednesday%>"></asp:checkbox></td>
                    <td><asp:checkbox id="chkThursday" runat="server" Text="<%$Resources:Strings, Thursday%>"></asp:checkbox></td>
                </tr>
                <tr>
                    <td><asp:checkbox id="chkFriday" runat="server" Text="<%$Resources:Strings, Friday%>"></asp:checkbox></td>
                    <td><asp:checkbox id="chkSaturday" runat="server" Text="<%$Resources:Strings, Saturday%>"></asp:checkbox></td>
                    <td><asp:checkbox id="chkSunday" runat="server" Text="<%$Resources:Strings, Sunday%>"></asp:checkbox></td>
                    <td></td>
                </tr>
            </table>
            <table id="MonthlyTable" style="display: none" role="presentation">
                <tr>
                    <td><asp:radiobutton id="optMonthlyDay" runat="server" GroupName="MonthlyGroup" Text="<%$Resources:Strings, Day %>" Checked="True"></asp:radiobutton>&nbsp;
                        <asp:textbox id="txtMonthEveryDay" runat="server" Width="40px" CssClass="fld"></asp:textbox>&nbsp;<%= Resources.Strings.OfEvery%>&nbsp;
                        <asp:textbox id="txtMonthEveryMonth" runat="server" Width="40px" CssClass="fld">1</asp:textbox>&nbsp;<%= Resources.Strings.Months%></td>
                </tr>
                <tr>
                    <td><asp:radiobutton id="optMonthlyThe" runat="server" GroupName="MonthlyGroup" Text="<%$Resources:Strings, The %>"></asp:radiobutton>&nbsp;<asp:dropdownlist id="lstMonthTheFrequency" runat="server" CssClass="selecttext">
                            <asp:ListItem Value="1" Selected="True" Text="<%$Resources:Strings, First %>"></asp:ListItem>
                            <asp:ListItem Value="2" Text="<%$Resources:Strings, Second %>"></asp:ListItem>
                            <asp:ListItem Value="3" Text="<%$Resources:Strings, Third %>"></asp:ListItem>
                            <asp:ListItem Value="4" Text="<%$Resources:Strings, Fourth %>"></asp:ListItem>
                            <asp:ListItem Value="-1" Text="<%$Resources:Strings, Last %>"></asp:ListItem>
                        </asp:dropdownlist><asp:dropdownlist id="lstMonthTheDay" runat="server" CssClass="selecttext">
                            <asp:ListItem Value="SU" Text="<%$Resources:Strings, Sunday %>"></asp:ListItem>
                            <asp:ListItem Value="MO" Text="<%$Resources:Strings, Monday %>" Selected="True"></asp:ListItem>
                            <asp:ListItem Value="TU" Text="<%$Resources:Strings, Tuesday %>"></asp:ListItem>
                            <asp:ListItem Value="WE" Text="<%$Resources:Strings, Wednesday %>"></asp:ListItem>
                            <asp:ListItem Value="TH" Text="<%$Resources:Strings, Thursday %>"></asp:ListItem>
                            <asp:ListItem Value="FR" Text="<%$Resources:Strings, Friday %>"></asp:ListItem>
                            <asp:ListItem Value="SA" Text="<%$Resources:Strings, Saturday %>"></asp:ListItem>
                        </asp:dropdownlist>&nbsp;<%= Resources.Strings.OfEvery%>
                        <asp:textbox id="txtMonthlyTheMonth" runat="server" Width="40px" CssClass="fld">1</asp:textbox>&nbsp;<%= Resources.Strings.Months%></td>
                </tr>
            </table>
            <table id="YearlyTable" style="display: none" role="presentation">
                <tr>
                    <td style="HEIGHT: 21px"><asp:radiobutton id="optYearlyEvery" runat="server" GroupName="YearlyGroup" Text="<%$Resources:Strings, Every %>" Checked="True"></asp:radiobutton>&nbsp;<asp:dropdownlist id="lstYearlyEveryMonth" runat="server" CssClass="selecttext">
                            <asp:ListItem Value="1" Text="<%$Resources:Strings, January %>"></asp:ListItem>
                            <asp:ListItem Value="2" Text="<%$Resources:Strings, February %>"></asp:ListItem>
                            <asp:ListItem Value="3" Text="<%$Resources:Strings, March %>"></asp:ListItem>
                            <asp:ListItem Value="4" Text="<%$Resources:Strings, April %>"></asp:ListItem>
                            <asp:ListItem Value="5" Text="<%$Resources:Strings, May %>"></asp:ListItem>
                            <asp:ListItem Value="6" Text="<%$Resources:Strings, June %>"></asp:ListItem>
                            <asp:ListItem Value="7" Text="<%$Resources:Strings, July %>"></asp:ListItem>
                            <asp:ListItem Value="8" Text="<%$Resources:Strings, August %>"></asp:ListItem>
                            <asp:ListItem Value="9" Text="<%$Resources:Strings, September %>"></asp:ListItem>
                            <asp:ListItem Value="10" Text="<%$Resources:Strings, October %>"></asp:ListItem>
                            <asp:ListItem Value="11" Text="<%$Resources:Strings, November %>"></asp:ListItem>
                            <asp:ListItem Value="12" Text="<%$Resources:Strings, December %>"></asp:ListItem>
                        </asp:dropdownlist><asp:textbox id="txtYearlyEveryDay" runat="server" Width="40px" CssClass="fld"></asp:textbox></td>
                </tr>
                <tr>
                    <td><asp:radiobutton id="optYearlyThe" runat="server" GroupName="YearlyGroup" Text="<%$Resources:Strings, The %>"></asp:radiobutton>&nbsp;<asp:dropdownlist id="lstYearlyTheFrequency" runat="server" CssClass="selecttext">
                            <asp:ListItem Value="1" Selected="True" Text="<%$Resources:Strings, First %>"></asp:ListItem>
                            <asp:ListItem Value="2" Text="<%$Resources:Strings, Second %>"></asp:ListItem>
                            <asp:ListItem Value="3" Text="<%$Resources:Strings, Third %>"></asp:ListItem>
                            <asp:ListItem Value="4" Text="<%$Resources:Strings, Fourth %>"></asp:ListItem>
                            <asp:ListItem Value="-1" Text="<%$Resources:Strings, Last %>"></asp:ListItem>
                        </asp:dropdownlist><asp:dropdownlist id="lstYearlyTheDay" runat="server" CssClass="selecttext">
                            <asp:ListItem Value="SU" Text="<%$Resources:Strings, Sunday %>"></asp:ListItem>
                            <asp:ListItem Value="MO" Selected="True" Text="<%$Resources:Strings, Monday %>"></asp:ListItem>
                            <asp:ListItem Value="TU" Text="<%$Resources:Strings, Tuesday %>"></asp:ListItem>
                            <asp:ListItem Value="WE" Text="<%$Resources:Strings, Wednesday %>"></asp:ListItem>
                            <asp:ListItem Value="TH" Text="<%$Resources:Strings, Thursday %>"></asp:ListItem>
                            <asp:ListItem Value="FR" Text="<%$Resources:Strings, Friday %>"></asp:ListItem>
                            <asp:ListItem Value="SA" Text="<%$Resources:Strings, Saturday %>"></asp:ListItem>
                        </asp:dropdownlist>&nbsp;<%=Resources.Strings.OfString %>&nbsp;
                        <asp:dropdownlist id="lstYearlyTheMonth" runat="server" CssClass="selecttext">
                            <asp:ListItem Value="1" Text="<%$Resources:Strings, January %>"></asp:ListItem>
                            <asp:ListItem Value="2" Text="<%$Resources:Strings, February %>"></asp:ListItem>
                            <asp:ListItem Value="3" Text="<%$Resources:Strings, March %>"></asp:ListItem>
                            <asp:ListItem Value="4" Text="<%$Resources:Strings, April %>"></asp:ListItem>
                            <asp:ListItem Value="5" Text="<%$Resources:Strings, May %>"></asp:ListItem>
                            <asp:ListItem Value="6" Text="<%$Resources:Strings, June %>"></asp:ListItem>
                            <asp:ListItem Value="7" Text="<%$Resources:Strings, July %>"></asp:ListItem>
                            <asp:ListItem Value="8" Text="<%$Resources:Strings, August %>"></asp:ListItem>
                            <asp:ListItem Value="9" Text="<%$Resources:Strings, September %>"></asp:ListItem>
                            <asp:ListItem Value="10" Text="<%$Resources:Strings, October %>"></asp:ListItem>
                            <asp:ListItem Value="11" Text="<%$Resources:Strings, November %>"></asp:ListItem>
                            <asp:ListItem Value="12" Text="<%$Resources:Strings, December %>"></asp:ListItem>
                        </asp:dropdownlist>&nbsp;</td>
                </tr>
            </table>
        </td>
    </tr>
    <tr>
        <td class="base3 titlerow" colSpan="2"><%=Resources.Strings.RangeOfRecurrence %></td>
    </tr>
    <tr>
        <td colSpan="2"><asp:radiobutton id="optRepeatCount" runat="server" GroupName="EndBy" Text="<%$Resources:Strings, EndAfter %>"></asp:radiobutton>&nbsp;<asp:textbox id="txtRepeatCount" runat="server" CssClass="fld" Width="40px">10</asp:textbox>&nbsp;<%=Resources.Strings.Occurrences %><br>
            <asp:radiobutton id="optRepeatUntil" runat="server" GroupName="EndBy" Text="<%$Resources:Strings, EndBy %>"></asp:radiobutton>&nbsp;<uc1:ctldate id="dteEndBy" runat="server" CssClass="fld"></uc1:ctldate></td>
    </tr>
</table>
