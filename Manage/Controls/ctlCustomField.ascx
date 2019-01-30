<%@ Control Language="VB" AutoEventWireup="false" Inherits="Intelledox.Manage.ctlCustomField" Codebehind="ctlCustomField.ascx.vb" %>
<%@ Register Src="ctlDate.ascx" TagName="ctlDate" TagPrefix="uc1" %>
<tr id="trCustom" runat="server" style="display:none">
    <td><asp:literal id="lblTitle" Runat="server" /></td>
    <td colspan="3">
        <asp:TextBox id="txtCustomValue" runat="server" style="width:300px;"></asp:TextBox>
        <uc1:ctlDate ID="dteCustomDate" runat="server" Visible="false" />
        <span id="spnImg" runat="server" visible="false">
        <img id="imgPreview" src="~/GetImage.ashx?Thumb=1" runat="server" alt="" /><br />
        <asp:FileUpload ID="filCustomImage" accept="image/*" multiple="false" runat="server" style="width:400px;" />
        </span>
        <asp:HiddenField ID="hidCustomFieldID" runat="server" />
    </td>
</tr>