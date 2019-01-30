<%@ Control Language="vb" AutoEventWireup="false" Inherits="Intelledox.Manage.ctlDate" Codebehind="ctlDate.ascx.vb" %>
<asp:textbox id="txtDate" runat="server" cssclass="field"></asp:textbox>
<asp:hyperlink id="lnkPickDate" runat="server">
	<asp:image runat="server" alternatetext="<%$Resources:Strings, SelectDate %>" tooltip="<%$Resources:Strings, SelectDate %>" id="imgCal" imageurl="~/images/IX_Calendar.svg" Height="16"></asp:image>
</asp:hyperlink>
