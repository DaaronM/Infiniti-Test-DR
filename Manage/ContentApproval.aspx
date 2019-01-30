<%@ Page Title="" Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ContentApproval" Codebehind="ContentApproval.aspx.vb" %>
<%@ Register Src="Controls/ctlDate.ascx" TagName="ctlDate" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnApprove" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Approve %>" />
            <asp:Button ID="btnCancel" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Cancel %>" />
        </div>
        <div class="body">
            <table class="subfield" cellspacing="0" align="center" role="presentation">
                <tr class="base3 titlerow">
                    <td colspan="2"><%= Resources.Strings.ApproveVersion%></td>
                </tr>
                <tr class="inforow">
                    <td><%= Resources.Strings.ContentApprovalMessage%></td>
                </tr>
                <tr>
                    <td>
                        <asp:radiobutton id="optIndefinite" runat="server" GroupName="ApprovalExpiry" Text="<%$Resources:Strings, ApproveIndefinitely%>" Checked="true">
                        </asp:radiobutton>
                        <br/>

                        <asp:radiobutton id="optUntil" runat="server" GroupName="ApprovalExpiry" Text="<%$Resources:Strings, ApproveUntil%>">
                        </asp:radiobutton>
                        &nbsp;
                        <uc1:ctlDate ID="dteUntil" runat="server" />
                        <asp:CustomValidator ID="valUntilDate" runat="server" ErrorMessage="" display="Dynamic" 
                                OnServerValidate="CheckUntilDate" CssClass="wrn"></asp:CustomValidator>
                        <br/>

                    </td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>
