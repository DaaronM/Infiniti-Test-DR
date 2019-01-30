<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="SearchTenantUsers.aspx.vb" Inherits="ManagementPortal.SearchTenantUsers" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnBack" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="searcharea">
            <table role="presentation">
                <tr>
                    <td>
                        <asp:Label ID="lblTenant" runat="server" Text="<%$Resources:Strings, Tenant %>" AssociatedControlID="lstTenants"></asp:Label>
                    </td>
                    <td>
                        <asp:DropDownList ID="lstTenants" runat="server" AutoPostBack="false">
                        </asp:DropDownList>&nbsp;&nbsp;
                    </td>
                    <td>
                        <asp:Button ID="btnGetEmails" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, GetEmails %>" />
                    </td>
                </tr>
            </table>
        </div>
        <div class="body">
            <table style="width:100%;" class="editsection" role="presentation">
                <tr>
                    <td class="cell-heading"><asp:Literal ID="litAdminList" runat="server" Text="<%$Resources:Strings, AdminList%>" /></td>
                </tr>
                <tr>
                    <td colspan="4" class="cell-normal">
                        <textarea id="txtAdminList" name="txtAdminList" cols="15" rows="10" class="field" style="width:60%" runat="server"></textarea>
                    </td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>

