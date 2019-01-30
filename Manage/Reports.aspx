<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Reports" Codebehind="Reports.aspx.vb" %>

<%@ Reference Control="~/controls/ctldate.ascx" %>
<%@ Register TagPrefix="uc1" TagName="ctlDate" Src="Controls/ctlDate.ascx" %>
<%@ Register assembly="Microsoft.ReportViewer.WebForms, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" namespace="Microsoft.Reporting.WebForms" tagprefix="rsweb" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>

    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnView" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, View %>" CausesValidation="true"/>
        </div>
        <div class="searcharea">
            <table role="presentation">
                <tr>
                    <td>
                        <asp:Label ID="litReport" runat="server" Text="<%$Resources:Strings, Report %>" AssociatedControlID="cboReport" />
                    </td>
                    <td colspan="3">
                        <asp:DropDownList ID="cboReport" runat="server" AutoPostBack="true">
                            <asp:ListItem Text="<%$Resources:Strings, Report_Usage %>" Selected="True"></asp:ListItem>
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr>
                    <td style="width:125px">
                        <label for="txtFrom"><%:Resources.Strings.From%></label>
                    </td>
                    <td>
                        <uc1:ctlDate ID="dteFrom" TextboxId="txtFrom" runat="server" ClientIDMode="Static"></uc1:ctlDate>
                    </td>
                    <td>
                        <label for="txtTo"><%:Resources.Strings.ToResource%></label>
                    </td>
                    <td>
                        <uc1:ctlDate ID="dteTo" TextboxId="txtTo" runat="server" ClientIDMode="Static"></uc1:ctlDate>
                    </td>
                </tr>
                <tr>
                    <td colspan="4">
                        <asp:CustomValidator ID="valCompareDates" runat="server" CssClass="wrn" OnServerValidate="valCompareDates_ServerValidate"></asp:CustomValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="litProject" runat="server" Text="<%$Resources:Strings, Project %>" Visible="false" AssociatedControlID="cboProject" />
                    </td>
                    <td colspan="3">
                        <asp:DropDownList ID="cboProject" runat="server" Visible="false">
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="litIncludeText" runat="server" Text="<%$Resources:Strings, IncludeText %>" Visible="false" AssociatedControlID="chkIncludeText" />
                    </td>
                    <td colspan="3">
                        <asp:CheckBox ID="chkIncludeText" runat="server" Visible="false">
                        </asp:CheckBox>
                    </td>
                </tr>
            </table>
        </div>
        <div class="body">
            <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="1000px" Height="775px" ShowRefreshButton="False" ExportContentDisposition="AlwaysInline" ShowToolBar="false">
            </rsweb:ReportViewer>
        </div>
    </div>
</asp:Content>

