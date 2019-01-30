<%@ Page Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" Inherits="ManagementPortal.ExtendTrial" CodeBehind="ExtendTrial.aspx.vb" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSubmit" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Submit %>" />
            <span class="tooldiv" id="divSubmit" runat="server"></span>
            <asp:Button ID="btnCancel" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Cancel %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <asp:Label ID="lblPerformedBy" runat="server" AssociatedControlID="txtPerformedBy" Text="<%$Resources:Strings, PerformedBy %>" />
                    </td>
                    <td>
                        <asp:TextBox id="txtPerformedBy" CssClass="fld" runat="server" Width="500px" />
                        <asp:RequiredFieldValidator ID="valPerformedBy" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtPerformedBy"
                            CssClass="wrn">
                        </asp:RequiredFieldValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblReason" runat="server" AssociatedControlID="txtReason" Text="<%$Resources:Strings, Reason %>" />
                    </td>
                    <td>
                        <asp:TextBox id="txtReason" CssClass="fld" runat="server" Width="500px" Rows="5" TextMode="MultiLine" />
                        <asp:RequiredFieldValidator ID="valReason" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtReason"
                            CssClass="wrn">
                        </asp:RequiredFieldValidator>
                    </td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>
