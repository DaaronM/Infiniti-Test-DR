<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ContentItemEdit" Codebehind="ContentItemEdit.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script type="text/javascript">

        // For document fragments
        function checkFormat(source, args) {
            var ctl = document.getElementById('<%=fileSelecter.ClientId %>');

            if (ctl.value != "" && ctl.value != null) {
                if (ctl.value.length > 3) {
                    if (ctl.value.toLowerCase().substring(ctl.value.length - 3, ctl.value.length) == "doc") {
                        args.IsValid = true;
                        return;
                    }
                }
                if (ctl.value.length > 4) {
                    if (ctl.value.toLowerCase().substring(ctl.value.length - 4, ctl.value.length) == "docx") {
                        args.IsValid = true;
                        return;
                    }
                }
            }

            alert('<%=Resources.Strings.InvalidDocUpload %>');
            args.IsValid = false;
        }
        
        // For images
        function resizeImage() {
            var imgDisplay = '<%=imgDisplay.ClientId %>';
            var txtScale = '<%=txtScale.ClientId %>';
            var originalHeight = <%=OriginalHeight() %>;
            var originalWidth = <%=OriginalWidth() %>;
            var scale;
            
            scale = document.getElementById(txtScale).value;
            
            if (document.getElementById(imgDisplay)) {
                if (!isNaN(scale) && scale > 0) {
                    document.getElementById(imgDisplay).height = originalHeight * (scale/100);
                    document.getElementById(imgDisplay).width = originalWidth * (scale/100);
                } else {
                    document.getElementById(imgDisplay).height = originalHeight;
                    document.getElementById(imgDisplay).width = originalWidth;
                }
            }
        }

        $(function() {

            $('#trComment').hide();
            $("input:file").change(function() {
                $('#trComment').show();
            });
            $('.txtText').on("propertychange change keyup paste input", function(){
                $('#trComment').show();
            });
        });

    </script>
    <style type="text/css">
        .fld 
        {
            width:400px;
        }
    </style>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <Controls:DeleteButton ID="btnDelete" runat="server" CssClass="toolbtn" CausesValidation="False"></Controls:DeleteButton>
            <asp:Literal ID="litProjects" runat="server"><span class="tooldiv"></span></asp:Literal>
            <asp:Button ID="btnVersions" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, VersionHistory %>" ToolTip="<%$Resources:Strings, VersionsHelp %>" />
            <asp:Button ID="btnProjects" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, RelatedProjects %>" CausesValidation="False" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="False" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblName" runat="server" Text="<%$Resources:Strings, Name %>"
                            AssociatedControlID="txtName"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtName" runat="server" MaxLength="200" CssClass="fld"></asp:TextBox><asp:RequiredFieldValidator
                            ID="valName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtName" CssClass="wrn"></asp:RequiredFieldValidator>
                    </td>
                </tr>
                <tr id="trLocation" runat="server" >
                    <td>
                        <asp:Label ID="lblLocation" runat="server" Text="<%$Resources:Strings, Location %>"
                            AssociatedControlID="lstLocation"></asp:Label>
                    </td>
                    <td>
                        <asp:DropDownList ID="lstLocation" runat="server" CssClass="fld" AutoPostBack="true">
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr>
                    <td valign="top">
                        <asp:Label ID="lblDescription" runat="server" Text="<%$Resources:Strings, Description %>"
                            AssociatedControlID="txtDescription"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtDescription" runat="server" TextMode="MultiLine" Rows="10" Columns="50" cssclass="fld"></asp:TextBox>
                    </td>
                </tr>
                <tr id="trScale" runat="server" visible="false">
                    <td>
                        <asp:Label ID="lblScale" runat="server" Text="<%$Resources:Strings, Scale %>" AssociatedControlID="txtScale"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtScale" runat="server" MaxLength="3" CssClass="fld"></asp:TextBox>
                        <asp:CompareValidator ID="valScale" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>" display="Dynamic" ControlToValidate="txtScale" Type="Integer" 
                            ValueToCompare="-1" Operator="GreaterThan" CssClass="wrn" Enabled="false"></asp:CompareValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblCategory" runat="server" Text="<%$Resources:Strings, Category %>"
                            AssociatedControlID="lstCategory"></asp:Label>
                    </td>
                    <td>
                        <asp:DropDownList ID="lstCategory" runat="server" CssClass="fld">
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblFolder" runat="server" Text="<%$Resources:Strings, Folder %>"
                            AssociatedControlID="lstFolder"></asp:Label>
                    </td>
                    <td>
                         <asp:DropDownList ID="lstFolder" runat="server" CssClass="fld">
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr id="trNewBinary" runat="server">
                    <td>
                        <asp:Label ID="lblNewBinary" runat="server" AssociatedControlID="fileSelecter"></asp:Label>
                    </td>
                    <td>
                        <asp:FileUpload ID="fileSelecter" runat="server" Width="400px" />
                        <asp:CustomValidator ID="valFileFormat" runat="server" ControlToValidate="fileSelecter" ClientValidationFunction="checkFormat" CssClass="wrn" Enabled="false"></asp:CustomValidator>
                    </td>
                </tr>
                <tr id="trText" runat="server" visible="false">
                    <td valign="top">
                        <asp:Label ID="lblText" runat="server" Text="<%$Resources:Strings, Text %>" AssociatedControlID="txtText"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtText" runat="server" CssClass="fld txtText" TextMode="MultiLine" Columns="30" Rows="30"></asp:TextBox>
                        <asp:HiddenField ID="hidTextChanged" runat="server" />
                    </td>
                </tr>
                <tr id="trComment">
                    <td>
                        <asp:Label ID="lblComment" runat="server" Text="<%$Resources:Strings, VersionComment %>" AssociatedControlID="txtComment"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtComment" runat="server" TextMode="MultiLine" Rows="5" Columns="5" cssclass="fld"></asp:TextBox>
                    </td>
                </tr>
                <tr id="trLink" runat="server" visible="false">
                    <td>
                        <asp:Label ID="lblLink" runat="server" Text="<%$Resources:Strings, Link %>"
                            AssociatedControlID="txtLink"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtLink" runat="server" MaxLength="255" CssClass="fld"></asp:TextBox>
                    </td>
                </tr>
            </table>
            <table align="center" role="presentation">
                <tr>
                    <td colspan="2"><br />
                        <a href="GetFragment.ashx" runat="server" id="lnkDownload" target="_blank" visible="false"></a>
                    </td>
                </tr>
            </table>
            <table align="center" role="presentation">
                <tr>
                    <td colspan="2"><br />
                        <img src="GetImage.ashx?Guid=" runat="server" id="imgDisplay" visible="false" alt="<%$Resources:Strings, ContentImage %>" />
                    </td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>

