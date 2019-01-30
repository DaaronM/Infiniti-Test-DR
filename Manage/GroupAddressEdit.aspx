<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.GroupAddressEdit" Codebehind="GroupAddressEdit.aspx.vb" %>
<%@ Reference Control="~/controls/ctlCustomField.ascx" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script src="Scripts/jquery-ui-1.12.1.custom.min.js" type="text/javascript"></script>
    <script type="text/javascript">
        function triggerEmailTextField() {
            if ($("#<%=chkEmailIndividualGroupMembers.ClientID%>").prop('checked')) {
                $('#<%=txtEmail.ClientID%>').prop("disabled", true);
            } else {
                $('#<%=txtEmail.ClientID%>').prop("disabled", false);
            }
        }
        $(document).ready(function () {
            triggerEmailTextField();
            $("#<%=chkEmailIndividualGroupMembers.ClientID%>").on('change', function () { return triggerEmailTextField(); });
        });

    </script>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Save %>" TabIndex="6" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" TabIndex="7" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table width="100%" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td><asp:Label ID="lblOrganisation" runat="server" Text="<%$Resources:Strings, GroupName %>"
                            AssociatedControlID="txtOrganisation"></asp:Label>
                    </td>
                    <td><asp:TextBox ID="txtOrganisation" runat="server" TabIndex="8" MaxLength="100"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPhoneNumber" runat="server" Text="<%$Resources:Strings, PhoneNumber %>"
                            AssociatedControlID="txtPhoneNumber"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPhoneNumber" runat="server" TabIndex="10" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblEmail" runat="server" Text="<%$Resources:Strings, Email %>" AssociatedControlID="txtEmail"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtEmail" runat="server" TabIndex="9" MaxLength="256"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblFaxNumber" runat="server" Text="<%$Resources:Strings, FaxNumber %>"
                            AssociatedControlID="txtFaxNumber"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtFaxNumber" runat="server" TabIndex="11" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblEmailIndividuals" runat="server" Text="<%$Resources:Strings, EmailIndividualGroupMembers %>" AssociatedControlID="chkEmailIndividualGroupMembers"></asp:Label>
                    </td>
                    <td>
                        <asp:CheckBox ID="chkEmailIndividualGroupMembers" runat="server" />
                    </td>
                </tr>
                <tr>
                    <th colspan="2">
                        <asp:Literal ID="Literal1" runat="server" Text="<%$Resources:Strings, StreetAddress %>" /></th>
                    <th colspan="2">
                        <asp:Literal ID="Literal2" runat="server" Text="<%$Resources:Strings, PostalAddress %>" /></th>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSAddress1" runat="server" Text="<%$Resources:Strings, AddressLine1 %>"
                            AssociatedControlID="txtSAddress1"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSAddress1" runat="server" TabIndex="12" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPAddress1" runat="server" Text="<%$Resources:Strings, AddressLine1 %>"
                            AssociatedControlID="txtPAddress1"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPAddress1" runat="server" TabIndex="18" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSAddress2" runat="server" Text="<%$Resources:Strings, AddressLine2 %>"
                            AssociatedControlID="txtSAddress2"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSAddress2" runat="server" TabIndex="13" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPAddress2" runat="server" Text="<%$Resources:Strings, AddressLine2 %>"
                            AssociatedControlID="txtPAddress2"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPAddress2" runat="server" TabIndex="19" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSSuburb" runat="server" Text="<%$Resources:Strings, SuburbTownCity %>"
                            AssociatedControlID="txtSSuburb"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSSuburb" runat="server" TabIndex="14" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPSuburb" runat="server" Text="<%$Resources:Strings, SuburbTownCity %>"
                            AssociatedControlID="txtPSuburb"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPSuburb" runat="server" TabIndex="20" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSState" runat="server" Text="<%$Resources:Strings, StateProvinceRegion %>"
                            AssociatedControlID="txtSState"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSState" runat="server" TabIndex="15" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPState" runat="server" Text="<%$Resources:Strings, StateProvinceRegion %>"
                            AssociatedControlID="txtPState"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPState" runat="server" TabIndex="21" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSPostal" runat="server" Text="<%$Resources:Strings, PostalZipCode %>"
                            AssociatedControlID="txtSPostal"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSPostal" runat="server" TabIndex="16" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPPostal" runat="server" Text="<%$Resources:Strings, PostalZipCode %>"
                            AssociatedControlID="txtPPostal"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPPostal" runat="server" TabIndex="22" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSCountry" runat="server" Text="<%$Resources:Strings, Country %>"
                            AssociatedControlID="txtSCountry"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSCountry" runat="server" TabIndex="17" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPCountry" runat="server" Text="<%$Resources:Strings, Country %>"
                            AssociatedControlID="txtPCountry"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPCountry" runat="server" TabIndex="23" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr id="trAdditional" runat="server" visible="false">
                    <th colspan="4">
                        <asp:Literal ID="litAdditional" runat="server" Text="<%$Resources:Strings, Additional %>" /></th>
                </tr>
                <asp:PlaceHolder ID="plhCustomFields" runat="server"></asp:PlaceHolder>
            </table>
        </div>
    </div>
</asp:Content>

